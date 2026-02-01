//
//  AddPlanFeature+Action.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 01/02/2026.
//

import ComposableArchitecture
import Foundation

extension AddPlanFeature {
    
    @CasePathable
    enum Action: ViewAction {
        
        case view(View)
        
        @CasePathable
        enum View {
            
            /// Called when view appears.
            case viewDidAppear
            
            /// Called when user taps dismiss button.
            case dismissTapped
            
            /// Called when user taps "Scan Plan" to use camera OCR.
            case scanPlanTapped
            
            /// Called when user taps "Manual Entry" to add plan manually.
            case manualEntryTapped
        }
        
    }
    
}
