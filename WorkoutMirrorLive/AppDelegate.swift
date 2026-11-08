//
//  AppDelegate.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 28/01/2026.
//

import UIKit
import ComposableArchitecture
import FirebaseCore
import HealthHub
import HealthKit
import OSLog
import SharedModels

class AppDelegate: NSObject, UIApplicationDelegate {

    // MARK: - Properties

    @Dependency(\.trainingReadinessBackgroundManager) var backgroundManager
    @Dependency(\.watchConnectivityClient) var watchConnectivityClient
    @Dependency(\.trainingManager) var trainingManager
    @Dependency(\.healthStore) var healthStore
    @Dependency(\.sessionClient) var sessionClient
    @Dependency(\.workoutActivityClient) var workoutActivityClient
    @Dependency(\.timerActivityClient) var timerActivityClient

    /// Captured before anything in this process can start a Live Activity, so the
    /// launch sweep reaps only banners an earlier process left behind.
    private let launchedAt = Date()

    // MARK: - Application Lifecycle

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        // Each build picks its own Firebase project by bundle ID, so both plists can live
        // on every branch and release ↔ develop merges never swap projects.
        if let options = FirebaseConfigFile.options(for: Bundle.main) {
            FirebaseApp.configure(options: options)
        }
        Task {
            await startBackgroundDelivery()
        }
        Task {
            await activateWatchConnectivity()
        }
        // Always-try crash recovery. The `UIScene.ConnectionOptions.shouldHandleActiveWorkoutRecovery`
        // flag from WWDC25 #322 is not yet available in the current iOS SDK (likely iOS 26
        // beta-only API). Until that lands, we call `recoverActiveWorkoutSession()`
        // unconditionally at launch — Apple guarantees it returns `nil` when there is no
        // session to recover, so the per-launch cost is one HK query (~10ms).
        Task {
            await recoverActiveWorkoutSession()
        }
        return true
    }

    // MARK: - Crash Recovery

    private func recoverActiveWorkoutSession() async {
        do {
            guard let session = try await healthStore.recoverActiveWorkoutSession() else {
                Logger.session.info("[Recovery] no active session to recover")
                await endOrphanedLiveActivities()
                return
            }
            Logger.session.info("[Recovery] recovered session (type=\(session.type.rawValue), state=\(session.state.rawValue))")
            trainingManager.recover(session: session)

            // Per WWDC25: `.primary` sessions need builder + dataSource rebuilt (the crashed
            // process owned them). `.mirroredFromRemoteDevice` recovery is complete after
            // `trainingManager.recover` — Watch owns the builder on its side.
            if session.type == .primary {
                try await sessionClient.recoverPrimarySession(session)
            }
        } catch {
            // No sweep here on purpose. A thrown query says nothing about whether a
            // workout is running, so reaping on it would end a correct banner whenever
            // HealthKit is briefly unavailable while the Watch is genuinely recording.
            // A banner left standing degrades to its stale state; one ended wrongly is gone.
            Logger.session.error("[Recovery] recoverActiveWorkoutSession failed: \(error.localizedDescription)")
        }
    }

    /// Clears a Live Activity the previous process left behind.
    ///
    /// The activity outlives its process while its id lives only in memory, so after a
    /// relaunch nothing can reach it — Apple's own guidance is to reconcile at launch.
    /// Only safe with no session to recover: then any banner still on screen is
    /// certainly stale. A recovered session keeps its activity, wrong or not, because
    /// this device cannot tell whether the Watch is still recording.
    private func endOrphanedLiveActivities() async {
        // Both types, because a session shows either banner and reaping one strands the other.
        let workouts = await workoutActivityClient.endOrphans(launchedAt)
        let timers = await timerActivityClient.endOrphans(launchedAt)
        guard workouts + timers > 0 else { return }
        Logger.session.info("[Recovery] ended \(workouts) workout + \(timers) timer Live Activity left by a previous process")
    }

    // MARK: - Background Delivery

    private func startBackgroundDelivery() async {
        do {
            try await backgroundManager.start()
            print("✅ AppDelegate: Background delivery started successfully")
        } catch {
            print("❌ AppDelegate: Failed to start background delivery: \(error)")
        }
    }

    // MARK: - Watch Connectivity

    private func activateWatchConnectivity() async {
        await watchConnectivityClient.initializeWatchConnectivity()
        Logger.wc.info("AppDelegate — WatchConnectivity activated on app launch")
    }
}
