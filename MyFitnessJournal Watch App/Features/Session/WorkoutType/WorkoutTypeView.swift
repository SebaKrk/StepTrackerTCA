//
//  WorkoutTypeView.swift
//  MyFitnessJournal Watch App
//
//  Created by Sebastian Sciuba on 02/06/2025.
//

import ComposableArchitecture
import SwiftUI
import WatchKit

@ViewAction(for: WorkoutTypeFeature.self)
struct WorkoutTypeView: View {
    
    // MARK: - Properties
    
    @Bindable var store: StoreOf<WorkoutTypeFeature>
    
    // MARK: - View
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(store.workoutTypes) { workoutType in
                    Button {
                        send(.selectedWorkoutType(workoutType))
                    } label: {
                        workoutTypeLabel(workoutType)
                    }
                }
            }
        }
        .listStyle(.carousel)
        .navigationBarTitle("Workout type")
        .navigationDestination(item: $store.scope(state: \.destination?.trainingSession,
                                                  action: \.destination.trainingSession)) { store in
            TrainingSessionTabView(store: store)
        }
    }
    
    private func workoutTypeLabel(_ workoutType: WorkoutType) -> some View {
        HStack {
            Text(workoutType.title)
            Spacer()
            Image(systemName: workoutType.iconName)
        }
    }

}
