//
//  StepTrackerTCAApp.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 21/12/2024.
//

import ComposableArchitecture
import SwiftUI

@main
struct StepTrackerTCAApp: App {
    
    var body: some Scene {
        WindowGroup {
            AppTabView(
                store: Store(initialState: AppTabFeature.State()) {
                    AppTabFeature()
                }
            )
        }
    }
    
}

//._printChanges()
