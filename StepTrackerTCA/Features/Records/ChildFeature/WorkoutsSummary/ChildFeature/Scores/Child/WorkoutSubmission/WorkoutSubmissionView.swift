//
//  WorkoutSubmissionView.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 12/04/2025.
//

import ComposableArchitecture
import SwiftUI

@ViewAction(for: WorkoutSubmissionFeature.self)
struct WorkoutSubmissionView: View {
    
    // MARK: - Properties
    
    @Bindable var store: StoreOf<WorkoutSubmissionFeature>
    
    // MARK: - View
    
    var body: some View {
        HStack {
            Text("WorkoutSubmissionFeature")
            Button {
                send(.add)
            } label: {
                Text("add")
            }
        }
        .onAppear {
            send(.viewDidAppear)
        }
        
    }
    
}
