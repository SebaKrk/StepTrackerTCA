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
                ForEach(store.workoutTypes) { workoutType in
                    Button {
                        send(.selectedWorkoutOption(workoutType))
                    } label: {
                        Text(workoutType.title)
                    }
                }
            }
            .listStyle(.carousel)
            .navigationBarTitle("Workouts")
            .sheet(item: $store.scope(state: \.destination?.openSummary,
                                      action: \.destination.openSummary)) { store in
                SummaryView(store: store)
            }
                                      .navigationDestination(
                                        item: $store.scope(
                                            state: \.destination?.workoutSession,
                                            action: \.destination.workoutSession)) { store in
                                                WorkoutSessionView(store: store)
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

//.navigationDestination(
//  item: $store.scope(
//      state: \.destination?.openTest,
//      action: \.destination.openTest)) { store in
//          HeartRateView(store: store)
//      }
