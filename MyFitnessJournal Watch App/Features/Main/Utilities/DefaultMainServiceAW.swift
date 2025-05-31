//
//  AuthorizationAW.swift
//  MyFitnessJournal Watch App
//
//  Created by Sebastian Sciuba on 23/05/2025.
//

import ComposableArchitecture
import Foundation

struct AuthorizationClientAW {
    var requestAuthorization: @Sendable () -> Void
}

extension DependencyValues {
    var authorizationClientAW: AuthorizationClientAW {
        get { self[AuthorizationKeyAW.self] }
        set { self[AuthorizationKeyAW.self] = newValue }
    }
}

private enum AuthorizationKeyAW: DependencyKey {
    static let liveValue: AuthorizationClientAW = {
        
        @Dependency(\.trainingManager) var manager
        
        return AuthorizationClientAW {
            manager.requestAuthorization()
        }
    }()
}

