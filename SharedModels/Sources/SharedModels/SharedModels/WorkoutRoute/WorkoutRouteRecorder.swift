//
//  WorkoutRouteRecorder.swift
//  SharedModels
//
//  Created by Sebastian Ściuba on 06/08/2026.
//

import CoreLocation
import Foundation
import HealthKit
import OSLog

/// Owns the live GPS pipeline of an outdoor workout: a `CLLocationManager`
/// feeding both a multicast `locations` stream (live speed metrics) and an
/// `HKWorkoutRouteBuilder` (silent route capture — the map appears only in the
/// post-workout summary).
///
/// One instance per workout, on whichever device owns the `HKWorkoutSession`
/// (iPhone-standalone: `iPhoneWorkoutSession`; Watch-primary: the Watch session
/// manager). Requires `NSLocationWhenInUseUsageDescription` and the `location`
/// background mode in the host target.
///
/// ## Threading
///
/// `CLLocationManager` needs a run loop — creation and every manager call hop to
/// the main queue. Delegate callbacks therefore land on main; shared state is
/// `lock`-guarded, streams use the multicast registry pattern (project rule:
/// stored single streams are bugs waiting to happen).
public final class WorkoutRouteRecorder: NSObject, @unchecked Sendable {

    // MARK: - Constants

    /// Fixes with accuracy worse than this are noise — dropped from both the
    /// route and the metrics stream (Apple workout-route sample uses the same).
    private static let maximumHorizontalAccuracy: CLLocationAccuracy = 50

    // MARK: - Dependencies

    private let healthStore: HKHealthStore

    // MARK: - State

    private var locationManager: CLLocationManager?
    private var routeBuilder: HKWorkoutRouteBuilder?

    private let lock = NSLock()
    private var locationContinuations: [UUID: AsyncStream<CLLocation>.Continuation] = [:]

    /// `finishRoute` on a builder with zero inserted samples throws — track
    /// whether anything was actually recorded.
    private var hasRouteData = false

    /// Guards `finishRoute` against double invocation (primary end path +
    /// safety-net end path may both reach it).
    private var routeFinished = false

    /// While `true`, incoming fixes are dropped entirely — nothing reaches the
    /// route or the metrics stream. GPS stays warm for an instant resume.
    private var isPaused = false

    private static let logger = Logger(subsystem: "SharedModels", category: "WorkoutRouteRecorder")

    /// `true` when the host target declares the `location` background mode.
    /// Both platforms declare it in `UIBackgroundModes` — App Store validation
    /// rejects `location` inside `WKBackgroundModes` (workout-processing only);
    /// the WK key is still read defensively.
    private static var supportsBackgroundLocation: Bool {
        let uiModes = Bundle.main.object(forInfoDictionaryKey: "UIBackgroundModes") as? [String] ?? []
        let wkModes = Bundle.main.object(forInfoDictionaryKey: "WKBackgroundModes") as? [String] ?? []
        return (uiModes + wkModes).contains("location")
    }

    // MARK: - Lifecycle

    public init(healthStore: HKHealthStore) {
        self.healthStore = healthStore
        super.init()
    }

    /// Requests when-in-use authorization (first ride only) and starts GPS
    /// updates + route collection. Safe to call once per workout.
    public func start() {
        lock.withLock {
            hasRouteData = false
            routeFinished = false
            isPaused = false
        }
        routeBuilder = HKWorkoutRouteBuilder(healthStore: healthStore, device: nil)
        DispatchQueue.main.async { [self] in
            let manager = CLLocationManager()
            manager.delegate = self
            manager.desiredAccuracy = kCLLocationAccuracyBest
            manager.activityType = .fitness
            // CoreLocation ASSERTS (crash, not error) when this flag is set
            // without the `location` background mode in the built Info.plist —
            // gate it so a target misconfiguration degrades to foreground-only
            // GPS instead of killing the workout.
            if Self.supportsBackgroundLocation {
                manager.allowsBackgroundLocationUpdates = true
            } else {
                Self.logger.error("no 'location' background mode in Info.plist — GPS limited to foreground")
            }
            #if os(iOS)
            manager.pausesLocationUpdatesAutomatically = false
            manager.showsBackgroundLocationIndicator = true
            #endif
            locationManager = manager
            if manager.authorizationStatus == .notDetermined {
                manager.requestWhenInUseAuthorization()
            }
            manager.startUpdatingLocation()
            Self.logger.info("start — GPS updates requested (auth=\(manager.authorizationStatus.rawValue))")
        }
    }

    /// Stops GPS updates and finishes the metrics stream. Route data already
    /// inserted stays in the builder for `finishRoute(for:)`.
    public func stop() {
        DispatchQueue.main.async { [self] in
            locationManager?.stopUpdatingLocation()
            locationManager = nil
        }
        let continuations = lock.withLock {
            let values = Array(locationContinuations.values)
            locationContinuations.removeAll()
            return values
        }
        for continuation in continuations {
            continuation.finish()
        }
        Self.logger.info("stop — GPS updates stopped")
    }

    /// Mirrors the `HKWorkoutSession` pause state — paused = fixes dropped, so
    /// the pause leaves no trace in the route or the metrics.
    public func setPaused(_ paused: Bool) {
        lock.withLock { isPaused = paused }
        Self.logger.info("setPaused(\(paused))")
    }

    /// Attaches the recorded route to the finalized workout. No-op when nothing
    /// was recorded (GPS denied, indoor ride) or when already finished.
    public func finishRoute(for workout: HKWorkout) async {
        let shouldFinish = lock.withLock { () -> Bool in
            guard hasRouteData, !routeFinished else { return false }
            routeFinished = true
            return true
        }
        guard shouldFinish, let routeBuilder else {
            Self.logger.info("finishRoute skipped — no route data or already finished")
            return
        }
        do {
            try await routeBuilder.finishRoute(with: workout, metadata: nil)
            Self.logger.info("finishRoute — route attached to workout \(workout.uuid.uuidString, privacy: .public)")
            await WorkoutFileLogger.shared.log("[Route] route saved for workout \(workout.uuid.uuidString)")
        } catch {
            Self.logger.error("finishRoute failed: \(error.localizedDescription, privacy: .public)")
            await WorkoutFileLogger.shared.log("[Route] finishRoute FAILED: \(error.localizedDescription)")
        }
    }

    // MARK: - Streams (computed, fresh per access)

    /// Accuracy-filtered GPS fixes — one consumer per workout engine, but
    /// multicast so re-subscription (recovery, restarts) keeps working.
    public var locations: AsyncStream<CLLocation> {
        AsyncStream { continuation in
            let id = UUID()
            lock.withLock { locationContinuations[id] = continuation }
            continuation.onTermination = { [weak self] _ in
                guard let self else { return }
                self.lock.withLock { _ = self.locationContinuations.removeValue(forKey: id) }
            }
        }
    }

    // MARK: - Private

    private func broadcast(_ location: CLLocation) {
        let continuations = lock.withLock { Array(locationContinuations.values) }
        for continuation in continuations {
            continuation.yield(location)
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension WorkoutRouteRecorder: CLLocationManagerDelegate {

    public func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        guard !lock.withLock({ isPaused }) else { return }
        let accurate = locations.filter {
            $0.horizontalAccuracy > 0 && $0.horizontalAccuracy <= Self.maximumHorizontalAccuracy
        }
        guard !accurate.isEmpty else { return }

        for location in accurate {
            broadcast(location)
        }

        lock.withLock { hasRouteData = true }
        routeBuilder?.insertRouteData(accurate) { success, error in
            if !success {
                Self.logger.error("insertRouteData failed: \(error?.localizedDescription ?? "unknown", privacy: .public)")
            }
        }
    }

    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Self.logger.info("authorization changed: \(manager.authorizationStatus.rawValue)")
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()
        case .denied, .restricted:
            // Ride continues without GPS: no route, speed falls back to
            // HealthKit distance deltas in `RideMetricsAccumulator`.
            manager.stopUpdatingLocation()
        default:
            break
        }
    }

    public func locationManager(
        _ manager: CLLocationManager,
        didFailWithError error: Error
    ) {
        Self.logger.error("didFailWithError: \(error.localizedDescription, privacy: .public)")
    }
}
