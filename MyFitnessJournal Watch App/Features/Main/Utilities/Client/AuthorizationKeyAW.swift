//
//  AuthorizationKeyAW.swift
//  MyFitnessJournal Watch App
//
//  Created by Sebastian Sciuba on 23/05/2025.
//

import ComposableArchitecture
import Foundation
import SharedModels

struct AuthorizationClientAW {
    var requestAuthorization: @Sendable () async -> Void
}

extension DependencyValues {
    var authorizationClientAW: AuthorizationClientAW {
        get { self[AuthorizationKeyAW.self] }
        set { self[AuthorizationKeyAW.self] = newValue }
    }
}

private enum AuthorizationKeyAW: DependencyKey {
    static let liveValue: AuthorizationClientAW = {
        
        @Dependency(\.authorizationManager) var manager
        
        return AuthorizationClientAW {
           await manager.requestAuthorization()
        }
    }()
}
