//
//  ActivityPickerFeature.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 02/09/2025.
//


import ComposableArchitecture
import Foundation
import SharedModels

@Reducer
struct BluetoothFeature {
    
    // MARK: - Dependency
    
    @Dependency(\.dismiss) var dismiss
    
    // MARK: - Reducer
    
    var body: some Reducer<State, Action> {
        Reduce<State, Action> { state, action in
            switch action {
                
                // MARK: - Action
                
                // MARK: - View Action
            case .view(.closeButtonTapped):
                return .run { send in
                    await self.dismiss()
                }
            }
        }
    }
}

/// Implementation of `BluetoothFeature` action
extension BluetoothFeature {
    
    @CasePathable
    enum Action: ViewAction {
        
        // MARK: - Actions
        
        // MARK: - View Actions
        case view(View)
        
        enum View {
            
            ///
            case closeButtonTapped
        }
    }
}

/// Implementation of `BluetoothFeature` state
extension BluetoothFeature {
    
    @ObservableState
    struct State {
        
    }
    
}

