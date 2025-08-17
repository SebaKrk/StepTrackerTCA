//
//  WorkoutDetailsView.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 01/08/2025.
//

import ComposableArchitecture
import SwiftUI

@ViewAction(for: WorkoutDetailsFeature.self)
struct WorkoutDetailsView: View {
    
    // MARK: - Properties
    @Bindable var store: StoreOf<WorkoutDetailsFeature>
    
    // MARK: - Body
    
    var body: some View {
        GlassButton("play") {
            send(.startWorkoutButtonTapped)
        }
        .navigationTitle(store.workout)
        .fullScreenCover(item: $store.scope(state: \.destination?.workoutMirroringView,
                                            action: \.destination.workoutMirroringView)) { store in
            WorkoutMirroringView(store: store)
        }
    }
}
