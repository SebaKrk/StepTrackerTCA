//
//  WorkoutMirrorApp.swift
//  WorkoutMirror Watch App
//
//  Created by Sebastian Sciuba on 25/03/2026.
//

import ComposableArchitecture
import SwiftUI

@main
struct WorkoutMirror_Watch_AppApp: App {
    var body: some Scene {
        WindowGroup {
            AppViewAW(store: Store(initialState: AppFeatureAW.State()) {
                AppFeatureAW()
            })
        }
    }
}
