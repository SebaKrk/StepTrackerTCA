//
//  WeightLiftingGoalsView.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 08/02/2025.
//

import ComposableArchitecture
import SwiftUI

@ViewAction(for: WeightLiftingGoalsFeature.self)
struct WeightLiftingGoalsView: View {
    
    // MARK: - Properties
    
    @Bindable var store: StoreOf<WeightLiftingGoalsFeature>
    
    // MARK: - View
    
    var body: some View {
        ScrollView {
            groupBoxGoals
                .frame(minHeight: 200)
        }
        .navigationTitle("WeightLifting Goals")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            toolbarButton
        }
        .onAppear {
            send(.viewDidAppear)
        }
        .sheet(item: $store.scope(state: \.destination?.openSetNewGoal, action: \.destination.openSetNewGoal), content: { store in
            SetEditGoalView(store: store)
                .presentationDetents([.medium, .large])
        })
        .sheet(item: $store.scope(state: \.destination?.openInfo, action: \.destination.openInfo), content: { store in
            ExerciseInfoView(store: store)
                .presentationDetents([.medium, .large])
        })
        .navigationDestination(
            item: $store.scope(
                state: \.destination?.showDetails,
                action: \.destination.showDetails)) { store in
                    ExerciseDetailsView(store: store)
                }
    }
    
    // MARK: - SubView
    
    @ToolbarContentBuilder
    var toolbarButton: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                send(.openSetEditGoal)
            } label: {
                Image(systemName: "plus")
            }
        }
    }
    
    private var groupBoxGoals: some View {
        GroupBox {
            VStack(alignment: .leading) {
                Text("wynik z ostatniego treningu")
                Text("ustawiony goal")
                Text("najlepszy wynik")
                HStack {
                    Spacer()
                    Button {
                        send(.openExerciseInfo)
                    } label: {
                        Image(systemName: "info.circle")
                            .foregroundStyle(.green)
                    }
                }
            }
        } label: {
            VStack {
                HStack {
                    Group {
                        Text("Clean&Jerk")
                            .font(.title3.bold())
                            .foregroundStyle(.green)
                        Spacer()
                        Button {
                            send(.navigationButtonTapped)
                        } label: {
                            Image(systemName: "chevron.right")
                        }
                    }
                    .foregroundStyle(.green)
                }
                Divider()
            }
        }
    }
}

#Preview {
    WeightLiftingGoalsView(store: Store(initialState: WeightLiftingGoalsFeature.State(), reducer: {
        WeightLiftingGoalsFeature(service: DefaultWeightLiftingGoalsServices())
    }))
}
