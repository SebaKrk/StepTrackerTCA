//
//  HealthDataListFeature+Action.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 22/12/2024.
//


extension HealthDataListFeature {
    
    @CasePathable
    enum Action {
        
        // MARK: - Actions
        
        // MARK: - View actions
        /// Used for view actions.
        case view(View)
     
        enum View {
            
            /// The action responsible for completing tasks as soon as the view is displayed.
            case viewDidAppear
        }
    }
    
}
