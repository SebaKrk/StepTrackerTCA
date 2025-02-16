//
//  ExerciseDetailsView.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 16/02/2025.
//

import ComposableArchitecture
import SwiftUI

@ViewAction(for: ExerciseDetailsFeature.self)
struct ExerciseDetailsView: View {
    
    // MARK: - Properties
    
    @Bindable var store: StoreOf<ExerciseDetailsFeature>
    
    // MARK: - View
    
    var body: some View {
        Text("ExerciseDetailsView")
    }
    
}

