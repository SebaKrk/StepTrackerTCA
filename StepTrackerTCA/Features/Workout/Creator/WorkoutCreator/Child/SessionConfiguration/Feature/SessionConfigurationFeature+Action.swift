//
//  SessionConfigurationFeature+Action.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 18/07/2025.
//

import ComposableArchitecture
import SharedModels

/// Implementation of `SessionConfigurationFeature` action
extension SessionConfigurationFeature {
    
    @CasePathable
    enum Action: ViewAction, BindableAction {
        
        // MARK: - Binding Action
        
        /// Handles changes in bindings for the state.
        case binding(BindingAction<State>)
        
        // MARK: - Actions
        
        /// Time value changed
        case timeChanged(Int?)
        
        /// Note text changed
        case noteChanged(String)
        
        // MARK: - View actions
        
        /// Used for view actions.
        case view(View)
        
        enum View {
            /// User tapped on a goal option
            case goalButtonTapped(SimpleWorkoutGoal)
            
            /// User tapped on note/info button
            case noteButtonTapped
            
            /// Note sheet was dismissed
            case noteDismissed
            
            /// Main sheet was dismissed
            case sheetDismissed
        }
        
        // MARK: - Delegate
        
        /// Delegate actions for parent communication
        case delegate(Delegate)
        
        enum Delegate {
            /// WarmUp configuration was updated
            case warmUpUpdated(WarmUpSession)
            
            /// CoolDown configuration was updated
            case coolDownUpdated(CoolDownSession)
        }
    }
}
