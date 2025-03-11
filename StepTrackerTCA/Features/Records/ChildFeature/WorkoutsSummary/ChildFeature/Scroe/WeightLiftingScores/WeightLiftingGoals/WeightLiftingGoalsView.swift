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
                buildScoreStack()
                infoButton
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
        .padding([.leading, .trailing], 12)
    }
    
    private func buildScoreStack() -> some View {
        VStack {
            createCellScoreView("calendar", "Last", "102", "12.02.2025")
            createCellScoreView("target", "Target", "120", "01.02.2024")
            createCellScoreView("trophy", "Best", "130", "01.01.2020")
        }
    }
    
    private func createCellScoreView(_ image: String, _ title: String, _ value: String, _ date: String) -> some View {
        GeometryReader { geometry in
            VStack {
                HStack {
                    HStack {
                        Image(systemName: image)
                            .foregroundStyle(.green)
                        Text(title)
                            .font(.system(size: 14, weight: .regular, design: .monospaced))
                    }
                    .frame(width: geometry.size.width * 0.3, alignment: .leading)
                    
                    Text("\(value) kg")
                        .font(.system(size: 14, weight: .semibold, design: .monospaced))
                        .frame(width: geometry.size.width * 0.4, alignment: .center)
                        .foregroundStyle(.green)
                    
                    Text(date)
                        .font(.system(size: 14, weight: .semibold, design: .monospaced))
                        .frame(width: geometry.size.width * 0.28, alignment: .trailing)
                }
                Divider()
            }
        }
    }
    
    private var infoButton: some View {
        HStack {
            Spacer()
            Button {
                send(.openExerciseInfo)
            } label: {
                Image(systemName: "info.circle")
                    .foregroundStyle(.green)
            }
        }
        .padding(.top,4)
    }
    
}

#Preview {
    WeightLiftingGoalsView(store: Store(initialState: WeightLiftingGoalsFeature.State(), reducer: {
        WeightLiftingGoalsFeature(service: DefaultWeightLiftingGoalsServices())
    }))
}
