//
//  ExerciseInfoView.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 16/02/2025.
//

import ComposableArchitecture
import SwiftUI

@ViewAction(for: ExerciseInfoFeature.self)
struct ExerciseInfoView: View {
    
    // MARK: - Properties
    
    @Bindable var store: StoreOf<ExerciseInfoFeature>
    
    // MARK: - View
    
    var body: some View {
        Text("ExerciseInfoView")
    }
    
}

