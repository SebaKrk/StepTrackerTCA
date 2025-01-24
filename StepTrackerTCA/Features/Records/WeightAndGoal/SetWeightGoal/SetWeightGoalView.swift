//
//  SetWeightGoalView.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 24/01/2025.
//

import ComposableArchitecture
import SwiftUI

struct SetWeightGoalView: View {
    
    // MARK: - Properties
    
    var store: StoreOf<SetWeightGoalFeature>
    
    // MARK: - View
    
    var body: some View {
        setWeightGoalBody
    }
    
    // MARK: - Subview
    
    private var setWeightGoalBody: some View {
        Text("SetWeightGoal")
    }
    
}
