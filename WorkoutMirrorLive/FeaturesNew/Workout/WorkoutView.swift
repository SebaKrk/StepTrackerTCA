//
//  WorkoutView.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 20/08/2025.
//

import ComposableArchitecture
import SwiftUI

@ViewAction(for: WorkoutFeature.self)
struct WorkoutView: View {
    
    // MARK: - Properties
    @Bindable var store: StoreOf<WorkoutFeature>
    
    // MARK: - Body
    
    var body: some View {
        Text("WorkoutFeature")
    }
}
