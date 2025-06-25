//
//  HealthKitPermission.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 28/12/2024.
//

import ComposableArchitecture
import Foundation
import Factory

@Reducer
struct HealthKitPermissionFeature {
    
    // MARK: - Dependency
    
    //@Injected(\.healthKitManager) private var healthKitManager
    @Dependency(\.authorizationManager) var authorizationManager
    @Dependency(\.dismiss) var dismiss
    
    // MARK: - Reducer
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
                // MARK: - Actions
                
            case .healthKitAuthorizationSuccess:
                return .run { send in
                    await send(.delegate(.success))
                    await self.dismiss()
                }
                
                // MARK: - View actions
                
            case .view(.appleHealthButtonPressed):
                state.isShowingHealthKitPermissions = true
                return .run { send in
                    //authorizationManager.requestAuthorization()
                    let result = await self.authorizationManager.requestAuthorization()
                    switch result {
                    case .success:
                        await send(.healthKitAuthorizationSuccess)
                        
                    case .failure(let error):
                        print("Authorization failed with error: \(error.localizedDescription)")
                    }
                }
                
            case .view(.viewDidAppear):
                state.hasSeen = true
                return .none
                
            default: return .none
            }
        }
    }
    
}
