//
//  SessionConfigurationFeature.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 18/07/2025.
//

import ComposableArchitecture
import Foundation
import SharedModels

@Reducer
struct SessionConfigurationFeature {
    
    // MARK: - Dependencies
    
    @Dependency(\.dismiss) var dismiss
    
    // MARK: - Reducer
    
    var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce { state, action in
            switch action {
                
                // MARK: - Binding
                
            case .binding(_):
                return .none
                
                // MARK: - Actions

                
            case let .timeChanged(time):
                state.time = time
                
                // Notify parent about configuration change
                return .run { [state] send in
                    switch state.phaseType {
                    case .warmUp:
                        await send(.delegate(.warmUpUpdated(state.toWarmUpSession)))
                    case .coolDown:
                        await send(.delegate(.coolDownUpdated(state.toCoolDownSession)))
                    }
                }
                
            case let .noteChanged(note):
                state.note = note
                
                // Notify parent about configuration change
                return .run { [state] send in
                    switch state.phaseType {
                    case .warmUp:
                        await send(.delegate(.warmUpUpdated(state.toWarmUpSession)))
                    case .coolDown:
                        await send(.delegate(.coolDownUpdated(state.toCoolDownSession)))
                    }
                }
                
                // MARK: - View Actions
                
            case .view(.noteButtonTapped):
                state.isNoteSheetPresented.toggle()
                return .none
                
            case .view(.noteDismissed):
                state.isNoteSheetPresented = false
                return .none
                
            case .view(.sheetDismissed):
                return .run { send in
                    await self.dismiss()
                }
                
                
            case let .view(.goalButtonTapped(goal)):
                state.goal = goal
                
                if goal == .open {
                    state.time = nil
                }
                
                // Notify parent about configuration change
                return .run { [state] send in
                    switch state.phaseType {
                    case .warmUp:
                        await send(.delegate(.warmUpUpdated(state.toWarmUpSession)))
                    case .coolDown:
                        await send(.delegate(.coolDownUpdated(state.toCoolDownSession)))
                    }
                }
                
                // MARK: - Delegate
                
            case .delegate:
                return .none
            }
        }
    }
}

// MARK: - PhaseType

extension SessionConfigurationFeature {
    enum PhaseType {
        case warmUp
        case coolDown
        
        var title: String {
            switch self {
            case .warmUp: return "Warm Up"
            case .coolDown: return "Cool Down"
            }
        }
        
        var infoPlaceholder: String {
            switch self {
            case .warmUp: return "Warm up note..."
            case .coolDown: return "Cool down note..."
            }
        }
    }
}
