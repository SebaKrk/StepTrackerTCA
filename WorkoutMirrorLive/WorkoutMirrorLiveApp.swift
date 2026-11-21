//
//  WorkoutMirrorLiveApp.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 29/07/2025.
//

import AppDatabase
import ComposableArchitecture
import SwiftUI

@main
struct WorkoutMirrorLiveApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    /// Why the database could not open; `nil` when the app started normally.
    private let databaseFailure: String?

    init() {
        // A failed migration must leave an app that can say so, not one that dies on every launch.
        databaseFailure = prepareDependencies { dependencies -> String? in
            do {
                try dependencies.bootstrapDatabase()
                return nil
            } catch {
                return String(describing: error)
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            if let databaseFailure {
                DatabaseFailureView(
                    message: String(localized: "Workouts in the Health app are safe. Close the app and open it again. If that does not help, contact us and include the code below."),
                    details: databaseFailure
                )
            } else {
                AppTabNewView(
                    store: Store(initialState: AppTabNewFeature.State()) {
                        AppTabNewFeature()
                        ///._printChanges()
                    } withDependencies: {
#if targetEnvironment(simulator)
                        $0.trainingReadinessClient = .mock
#endif
                    }
                )
            }
        }
    }
}

//            HealthMetricCardsView()

//@main
//struct WorkoutMirrorLiveApp: App {
//    var body: some Scene {
//        WindowGroup {
//            AppTabView(
//                store: Store(initialState: AppTabFeature.State()) {
//                    AppTabFeature()
//                }
//            )
//        }
//    }
//}

//@main
//struct WorkoutMirrorLiveApp: App {
//
//    var body: some Scene {
//        WindowGroup {
//            AppTabViewTest()
//        }
//    }
//}
