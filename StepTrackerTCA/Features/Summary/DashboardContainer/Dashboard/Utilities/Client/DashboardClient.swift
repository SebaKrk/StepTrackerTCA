//
//  DashboardClient.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 22/06/2025.
//

import ComposableArchitecture
import Foundation

public struct DashboardClient {
    var setupRemoteSessionHandler: @Sendable () async -> Void
}

extension DependencyValues {
    var dashboardClient: DashboardClient {
        get { self[DashboardClientKey.self] }
        set { self[DashboardClientKey.self] = newValue }
    }
}

private enum DashboardClientKey: DependencyKey {
    
    static let liveValue: DashboardClient = {
        
        @Dependency(\.trainingManager) var manager
        
        return DashboardClient {
            manager.setupRemoteSessionHandler()
        }
    }()
    
}
