//
//  RouteDetailsFeature.swift
//  MyFitnessJournal
//
//  Created by Sebastian Ściuba on 06/08/2026.
//

import ComposableArchitecture
import CoreLocation
import HealthHub
import HealthKit
import SharedModels
import SwiftUI

/// Route drill-in of the Activity Details screen: distance statistics, a
/// zone-colored static map, and scrubbable elevation + pace charts whose shared
/// selection highlights the matching point on the map (Apple Fitness-style).
/// Everything is derived on the fly from the saved workout, its route samples
/// and HealthKit HR samples ("derive, don't persist" — works retroactively for
/// any workout with a route).
@Reducer
struct RouteDetailsFeature {

    /// One chart bar: a minute of the workout with its average speed, average
    /// altitude and a representative route coordinate (drives the map highlight).
    struct RouteMinutePoint: Identifiable {
        let minute: Date
        let speed: Double
        let altitude: Double
        let coordinate: CLLocationCoordinate2D

        var id: Date { minute }
    }

    /// Contiguous stretch of the route ridden in one HR zone — rendered as a
    /// polyline in the zone's color.
    struct ZoneSegment: Identifiable, Sendable {
        let id: Int
        let zone: HeartRateZone
        let coordinates: [CLLocationCoordinate2D]
    }

    // MARK: - Dependency

    @Dependency(\.healthStore) var healthStore

    // MARK: - State

    @ObservableState
    struct State {

        /// Color representing training readiness level, shared across features.
        @Shared(.inMemory(.readinessLevelColor))
        var color: Color = .gray

        let workout: HKWorkout
        let locations: [CLLocation]
        let coordinates: [CLLocationCoordinate2D]

        /// User's maximum heart rate — classifies HR samples into zones.
        let maxHeartRate: Int

        /// Total distance in meters — from the workout's HealthKit statistics.
        let distance: Double?

        /// Average speed in m/s — distance over the pause-aware `duration`.
        let averageSpeed: Double?

        /// Fastest instantaneous speed in m/s — from the route's GPS samples.
        let maxSpeed: Double?

        /// Per-minute buckets for the charts. Minutes with no GPS fixes
        /// (pause) are simply absent — the charts show a gap, like Apple.
        let pacePoints: [RouteMinutePoint]

        /// Chart scrub position — SHARED by the pace and elevation charts, so
        /// scrubbing either one highlights both plus the map point.
        var selectedMinute: Date?

        /// Route split into per-HR-zone stretches. `nil` until loaded; empty =
        /// no HR samples (map falls back to the single-color polyline).
        var zoneSegments: [ZoneSegment]?

        /// Dominant HR zone per chart minute — colors the speed bars in step
        /// with the zone-colored route. Empty = no HR data (bars keep the
        /// readiness color).
        var minuteZones: [Date: HeartRateZone] = [:]

        /// Watch-recorded running dynamics (power, cadence, stride…). `nil`
        /// until loaded or for non-running workouts; `isEmpty` = no Watch data
        /// (section hidden).
        var runningDynamics: RunningDynamics?

        /// Running shows pace (min/km); everything else shows speed (km/h).
        var isPaceBased: Bool {
            workout.workoutActivityType == .running
        }

        /// The bucket under the scrub cursor — drives the map marker and the
        /// chart annotations. Minute-granularity match (Charts reports the
        /// selected date with sub-minute precision).
        var selectedPoint: RouteMinutePoint? {
            guard let selectedMinute else { return nil }
            return pacePoints.first {
                Calendar.current.isDate($0.minute, equalTo: selectedMinute, toGranularity: .minute)
            }
        }

        init(workout: HKWorkout, locations: [CLLocation], maxHeartRate: Int) {
            self.workout = workout
            self.locations = locations
            self.coordinates = locations.map(\.coordinate)
            self.maxHeartRate = maxHeartRate

            let distanceType: HKQuantityType = workout.workoutActivityType == .cycling
                ? HKQuantityType(.distanceCycling)
                : HKQuantityType(.distanceWalkingRunning)
            let meters = workout.statistics(for: distanceType)?
                .sumQuantity()?
                .doubleValue(for: .meter())
            self.distance = meters

            if let meters, workout.duration > 0 {
                self.averageSpeed = meters / workout.duration
            } else {
                self.averageSpeed = nil
            }

            // CoreLocation marks an unknown speed as negative — filter before max.
            self.maxSpeed = locations.map(\.speed).filter { $0 > 0 }.max()

            self.pacePoints = Self.minuteBuckets(locations: locations, workoutStart: workout.startDate)
        }

        /// Buckets GPS samples into workout minutes: average of the valid
        /// sample speeds/altitudes + the middle fix as the map coordinate.
        private static func minuteBuckets(
            locations: [CLLocation],
            workoutStart: Date
        ) -> [RouteMinutePoint] {
            let grouped = Dictionary(grouping: locations) { location in
                max(0, Int(location.timestamp.timeIntervalSince(workoutStart) / 60))
            }
            return grouped.compactMap { minuteIndex, samples in
                let speeds = samples.map(\.speed).filter { $0 >= 0 }
                guard !speeds.isEmpty else { return nil }
                let altitudes = samples.map(\.altitude)
                return RouteMinutePoint(
                    minute: workoutStart.addingTimeInterval(TimeInterval(minuteIndex) * 60),
                    speed: speeds.reduce(0, +) / Double(speeds.count),
                    altitude: altitudes.reduce(0, +) / Double(altitudes.count),
                    coordinate: samples[samples.count / 2].coordinate
                )
            }
            .sorted { $0.minute < $1.minute }
        }
    }

    // MARK: - Action

    enum Action: BindableAction {
        case binding(BindingAction<State>)

        /// View appeared — loads HR samples and builds the zone-colored route.
        case onAppear

        /// HR alignment finished: route zone segments + per-minute zones for
        /// the speed bars (both empty = no HR data).
        case hrDataComputed([ZoneSegment], [Date: HeartRateZone])

        /// Watch running dynamics loaded (`isEmpty` = no data, section hidden).
        case runningDynamicsLoaded(RunningDynamics)
    }

    // MARK: - Reducer

    var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce { state, action in
            switch action {

            case .onAppear:
                guard state.zoneSegments == nil else { return .none }
                let loadHRData: Effect<Action> = .run { [healthStore,
                                                         workout = state.workout,
                                                         locations = state.locations,
                                                         maxHR = state.maxHeartRate] send in
                    let samples = (try? await WorkoutSummaryLoader.heartRateSamples(
                        for: workout,
                        healthStore: healthStore
                    )) ?? []
                    let segments = Self.zoneSegments(
                        locations: locations,
                        samples: samples,
                        maxHR: maxHR
                    )
                    let minuteZones = Self.minuteZones(
                        samples: samples,
                        workoutStart: workout.startDate,
                        maxHR: maxHR
                    )
                    await send(.hrDataComputed(segments, minuteZones))
                }
                guard state.isPaceBased else { return loadHRData }
                return .merge(
                    loadHRData,
                    .run { [healthStore, workout = state.workout] send in
                        let dynamics = await RunningDynamicsLoader.load(
                            for: workout,
                            healthStore: healthStore
                        )
                        await send(.runningDynamicsLoaded(dynamics))
                    }
                )

            case let .hrDataComputed(segments, minuteZones):
                state.zoneSegments = segments
                state.minuteZones = minuteZones
                return .none

            case let .runningDynamicsLoaded(dynamics):
                state.runningDynamics = dynamics
                return .none

            case .binding:
                return .none
            }
        }
    }

    // MARK: - Zone segments

    /// Aligns each GPS fix with the HR sample closest in time (both series are
    /// chronological — two-pointer sweep) and groups contiguous same-zone runs
    /// into polyline segments. Boundary points are duplicated so consecutive
    /// segments connect without gaps.
    private static func zoneSegments(
        locations: [CLLocation],
        samples: [(date: Date, bpm: Double)],
        maxHR: Int
    ) -> [ZoneSegment] {
        guard !samples.isEmpty, locations.count >= 2, maxHR > 0 else { return [] }

        var segments: [ZoneSegment] = []
        var currentZone: HeartRateZone?
        var currentCoordinates: [CLLocationCoordinate2D] = []
        var sampleIndex = 0

        for location in locations {
            while sampleIndex + 1 < samples.count,
                  abs(samples[sampleIndex + 1].date.timeIntervalSince(location.timestamp))
                    <= abs(samples[sampleIndex].date.timeIntervalSince(location.timestamp)) {
                sampleIndex += 1
            }
            let zone = HeartRateZone.zone(
                bpm: Int(samples[sampleIndex].bpm.rounded()),
                maxHR: maxHR
            )
            if zone != currentZone {
                if let finishedZone = currentZone, !currentCoordinates.isEmpty {
                    segments.append(ZoneSegment(
                        id: segments.count,
                        zone: finishedZone,
                        coordinates: currentCoordinates + [location.coordinate]
                    ))
                }
                currentZone = zone
                currentCoordinates = []
            }
            currentCoordinates.append(location.coordinate)
        }

        if let currentZone, currentCoordinates.count >= 2 {
            segments.append(ZoneSegment(
                id: segments.count,
                zone: currentZone,
                coordinates: currentCoordinates
            ))
        }
        return segments
    }

    /// Average BPM per workout minute → zone. Uses the SAME minute bucketing
    /// as `State.minuteBuckets`, so the dictionary keys match the chart bars'
    /// `minute` dates exactly.
    private static func minuteZones(
        samples: [(date: Date, bpm: Double)],
        workoutStart: Date,
        maxHR: Int
    ) -> [Date: HeartRateZone] {
        guard !samples.isEmpty, maxHR > 0 else { return [:] }
        let grouped = Dictionary(grouping: samples) { sample in
            max(0, Int(sample.date.timeIntervalSince(workoutStart) / 60))
        }
        return grouped.reduce(into: [:]) { result, entry in
            let (minuteIndex, minuteSamples) = entry
            let averageBPM = minuteSamples.map(\.bpm).reduce(0, +) / Double(minuteSamples.count)
            let minute = workoutStart.addingTimeInterval(TimeInterval(minuteIndex) * 60)
            result[minute] = HeartRateZone.zone(bpm: Int(averageBPM.rounded()), maxHR: maxHR)
        }
    }
}
