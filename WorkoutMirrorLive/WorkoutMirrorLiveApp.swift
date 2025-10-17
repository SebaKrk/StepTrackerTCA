//
//  WorkoutMirrorLiveApp.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 29/07/2025.
//

import ComposableArchitecture
import SwiftUI

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

@main
struct WorkoutMirrorLiveApp: App {
    var body: some Scene {
        WindowGroup {
//            HealthMetricCardsView()
            AppTabNewView(
                store: Store(initialState: AppTabNewFeature.State()) {
                    AppTabNewFeature()
                }
            )
        }
    }
}
