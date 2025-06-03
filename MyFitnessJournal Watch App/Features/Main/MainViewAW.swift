//
//  MainViewAW.swift
//  MyFitnessJournal Watch App
//
//  Created by Sebastian Sciuba on 19/05/2025.
//

import ComposableArchitecture
import SwiftUI

@ViewAction(for: MainFeatureAW.self)
struct MainViewAW: View {
    
    // MARK: - Properties
    
    @Bindable var store: StoreOf<MainFeatureAW>
    
    // MARK: - View
    
    var body: some View {
        NavigationStack {
            //List(selection: $store.selectedTab) {
            List {
                ForEach(store.workoutOptions) { workoutOption in
                    Button {
                        send(.selectedWorkoutOption(workoutOption))
                    } label: {
                        Text(workoutOption.title)
                    }
                }
            }
            .listStyle(.carousel)
            .navigationBarTitle("Workouts")
            .sheet(item: $store.scope(state: \.destination?.openTrainingSummary,
                                      action: \.destination.openTrainingSummary)) { store in
                TrainingSummaryView(store: store)
            }
            .navigationDestination(item: $store.scope(state: \.destination?.openWorkoutType,
                                                      action: \.destination.openWorkoutType)) { store in
                WorkoutTypeView(store: store)
            }
        }
        .onAppear {
            send(.viewDidAppear)
        }
        
    }
    
}

#Preview {
    MainViewAW(store: Store(initialState: MainFeatureAW.State(), reducer: {
        MainFeatureAW()
    }))
}
