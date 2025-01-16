//
//  StepPieWidgetFeature+Action.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 16/01/2025.
//

import ComposableArchitecture
import Foundation


/// Implementation of `StepPieWidgetFeature` action
extension StepPieWidgetFeature {
    
    @CasePathable
    enum Action: ViewAction {
        
        // MARK: - Actions
        
        // MARK: - View Actions
        case view(View)
        
        enum View {
            /// The action responsible for completing tasks as soon as the view is displayed.
            case viewDidAppear
            
        }
    }
                    
}
