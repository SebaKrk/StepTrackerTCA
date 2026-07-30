//
//  WorkoutMirrorApp.swift
//  WorkoutMirror Watch App
//
//  Created by Sebastian Sciuba on 25/03/2026.
//

import ComposableArchitecture
import OSLog
import SharedModels
import SwiftUI

@main
struct WorkoutMirror_Watch_AppApp: App {

    /// Registers `WatchAppDelegate.handle(_:)` so that `HKHealthStore.startWatchApp(toHandle:)`
    /// on iPhone delivers the workout configuration here before the scene is rendered.
    @WKApplicationDelegateAdaptor(WatchAppDelegate.self) var appDelegate

    init() {
        Logger.appAW.info("Watch app launched — WorkoutMirror Watch App started")
    }

    var body: some Scene {
        WindowGroup {
            AppViewAW(store: Store(initialState: AppFeatureAW.State()) {
                AppFeatureAW()
            })
        }
    }
}
