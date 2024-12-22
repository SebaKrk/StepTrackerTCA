//
//  AddMetricDataFeature.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 22/12/2024.
//

import ComposableArchitecture
import Foundation

@Reducer
struct AddMetricDataFeature {
    
    // MARK: - Reducer
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            
            default: return .none
            }
        }
        
    }
}
