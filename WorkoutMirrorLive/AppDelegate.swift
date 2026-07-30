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

    // MARK: - Application Lifecycle

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        // Firebase boots only when its config file is bundled — the plist ships in
        // release builds only, so dev builds (no plist) leave crash reporting dormant.
        if Bundle.main.url(forResource: "GoogleService-Info", withExtension: "plist") != nil {
            FirebaseApp.configure()
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
