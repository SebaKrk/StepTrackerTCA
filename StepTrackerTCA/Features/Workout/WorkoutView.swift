//
//  WorkoutView.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 12/01/2025.
//

import ComposableArchitecture
import SwiftUI

@ViewAction(for: WorkoutFeature.self)
struct WorkoutView: View {
    
    // MARK: - Properties
    
    @Bindable var store: StoreOf<WorkoutFeature>
    
    // MARK: - View
    
    var body: some View {
        Text("Workout")
            .onAppear {
                send(.viewDidAppear)
            }
    }
    
}
