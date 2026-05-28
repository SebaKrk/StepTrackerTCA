//
//  AppDelegate.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 28/01/2026.
//

import UIKit
import ComposableArchitecture
import HealthHub
import OSLog
import SharedModels

class AppDelegate: NSObject, UIApplicationDelegate {

    // MARK: - Properties

    @Dependency(\.trainingReadinessBackgroundManager) var backgroundManager
    @Dependency(\.watchConnectivityClient) var watchConnectivityClient
    @Dependency(\.trainingManager) var trainingManager
    @Dependency(\.healthStore) var healthStore

    // MARK: - Application Lifecycle

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        Task {
            await startBackgroundDelivery()
        }
        Task {
            await activateWatchConnectivity()
        }
        return true
    }

    // MARK: - Scene Configuration (R3 — Crash Recovery)

    /// Per Apple WWDC25 #322 — when iOS resurfaces the app after a crash that left an
    /// active workout session in HealthKit, `options.shouldHandleActiveWorkoutRecovery`
    /// is `true`. We must call `HKHealthStore.recoverActiveWorkoutSession()` to re-attach
    /// the session, then rebuild its builder/dataSource (R3) inside `TrainingManager`.
    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        if options.shouldHandleActiveWorkoutRecovery {
            Logger.session.info("[Recovery] shouldHandleActiveWorkoutRecovery=true — attempting recovery")
            Task {
                await recoverActiveWorkoutSession()
            }
        }
        return UISceneConfiguration(
            name: "Default Configuration",
            sessionRole: connectingSceneSession.role
        )
    }

    private func recoverActiveWorkoutSession() async {
        do {
            guard let session = try await healthStore.recoverActiveWorkoutSession() else {
                Logger.session.info("[Recovery] no active session to recover")
                return
            }
            Logger.session.info("[Recovery] recovered session (type=\(session.type.rawValue), state=\(session.state.rawValue))")
            trainingManager.recover(session: session)
        } catch {
            Logger.session.error("[Recovery] recoverActiveWorkoutSession failed: \(error.localizedDescription)")
        }
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
