//
//  PersonFeature.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 10/08/2025.
//

import ComposableArchitecture
import Foundation
import HealthHub

@Reducer
struct PersonFeature {
    
    // MARK: - Dependency
    
    @Dependency(\.authorizationManager) var authorizationManager
    
    // MARK: - Reducer
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
                
                // MARK: - Action
            case .healthKitAuthorizationSuccess:
                return .run { send in
                    let debugStatuses = await self.authorizationManager.authorizationStatuses()
                    dump(debugStatuses)
                }
                
                // MARK: - View Action
            case .view(.requestAuthorizationButtonTapped):
                return .run { send in
                    let result = await self.authorizationManager.requestAuthorization()
                    switch result {
                    case .success:
                        await send(.healthKitAuthorizationSuccess)
                        
                    case .failure(let error):
                        print("Authorization failed with error: \(error.localizedDescription)")
                    }
                }
                
            case .view(.viewDidAppear):
                return .send(.internalAction(.checkAuthorization))
                
            case .view(.debugAuthorizationStatuses):
                return .send(.healthKitAuthorizationSuccess)
                
                // MARK: Internal Action
                
            case .internalAction(.checkAuthorization):
                return .run { send in
                    let status = await self.authorizationManager.isAuthorizedForAllRequiredShareTypes()
                    await send(.internalAction(.authorizationStatusResponse(status)))
                }
                
            case let .internalAction(.authorizationStatusResponse(status)):
                state.authorizationStatus = status
                return .none
            }
        }
    }
    
}

/// Implementation of `PersonFeature` action
extension PersonFeature {
    
    @CasePathable
    enum Action: ViewAction {
        
        // MARK: - Actions
        
        case healthKitAuthorizationSuccess
                
        // MARK: - View Actions
        
        case view(View)
        
        enum View {
                  
            ///
            case requestAuthorizationButtonTapped
            
            ///
            case debugAuthorizationStatuses
            
            /// Action triggered when the view appears on the screen.
            case viewDidAppear
        }
        
        case internalAction(Internal)
        
        enum Internal {
            
            ///
            case authorizationStatusResponse(Bool)
            
            ///
            case checkAuthorization
        }
    }
}

/// Implementation of `PersonFeature` state
extension PersonFeature {
    
    @ObservableState
    struct State {
        
        // MARK: - Properties
        var authorizationStatus: Bool?
    }
    
}
