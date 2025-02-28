//
//  StepTrackerTCAApp.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 21/12/2024.
//

import ComposableArchitecture
import Factory
import SwiftUI
import OSLog

@main
struct StepTrackerTCAApp: App {
    
    // MARK: - Properties
    
    private let coreDataManager = Container.shared.coreDataManger()
    
    // MARK: - Lifecycle
    
    init() {
#if DEBUG
        os_log("Database URL - \(URL.applicationSupportDirectory.path(percentEncoded: false))")
#endif
    }
    
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
