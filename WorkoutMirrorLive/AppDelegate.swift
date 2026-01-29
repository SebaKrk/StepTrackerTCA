//
//  AppDelegate.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 28/01/2026.
//


import UIKit
import ComposableArchitecture
import HealthHub

class AppDelegate: NSObject, UIApplicationDelegate {
    
    // MARK: - Properties
    
    @Dependency(\.trainingReadinessBackgroundManager) var backgroundManager
    
    // MARK: - Application Lifecycle
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        Task {
            await startBackgroundDelivery()
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
}
