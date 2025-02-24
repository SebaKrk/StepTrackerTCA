//
//  StepTrackerTCAApp.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 21/12/2024.
//

import ComposableArchitecture
import Factory
import SwiftData
import SwiftUI
import OSLog

@main
struct StepTrackerTCAApp: App {
    
    // MARK: - Lifecycle
    
    init() {
#if DEBUG
        os_log("Database URL - \(URL.applicationSupportDirectory.path(percentEncoded: false))")
#endif
    }
    
//    @Injected(\.swiftDataManager) private var swiftDataManager
    
    var body: some Scene {
        WindowGroup {
            AppTabView(
                store: Store(initialState: AppTabFeature.State()) {
                    AppTabFeature()
                }
            )
        }
//        .modelContainer(swiftDataManager.container)
    }
    
}
//._printChanges()
