//
//  WeightGoalWidgetView.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 16/01/2025.
//

import ComposableArchitecture
import SwiftUI

@ViewAction(for: WeightGoalWidgetFeature.self)
struct WeightGoalWidgetView: View {
    
    // MARK: - Properties
    
    @Bindable var store: StoreOf<WeightGoalWidgetFeature>
    
    // MARK: - View
    
    var body: some View {
        Text("WeightGoalWidgetFeature")
            .onAppear {
                send(.viewDidAppear)
            }
    }
    
}

