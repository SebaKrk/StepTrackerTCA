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
