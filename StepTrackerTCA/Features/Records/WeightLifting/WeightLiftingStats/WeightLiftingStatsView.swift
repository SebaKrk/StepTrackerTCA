//
//  WeightLiftingStatsView.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 08/02/2025.
//

import ComposableArchitecture
import SwiftUI

@ViewAction(for: WeightLiftingStatsFeature.self)
struct WeightLiftingStatsView: View {
    
    // MARK: - Properties
    
    @Bindable var store: StoreOf<WeightLiftingStatsFeature>
    
    // MARK: - View
    
    var body: some View {
        Group {
            weightLiftingGoalsBody
        }
        .onAppear {
            send(.viewDidAppear)
        }
        .navigationDestination(
            item: $store.scope(
                state: \.destination?.open,
                action: \.destination.open)) { store in
                    WeightLiftingGoalsView(store: store)
                }
    }
    
    // MARK: - SubView
    
    private var weightLiftingGoalsBody: some View {
        weightLiftingGoalsWidget
    }
    
    private var weightLiftingGoalsWidget: some View {
        GroupBox {
            weightLiftingGoalsContent
        } label: {
            weightLiftingGoalsTitleHeader
        }
        .frame(minHeight: 200)
    }
    
    private var weightLiftingGoalsTitleHeader: some View {
        WidgetHeaderView(title: "WeightLifting", systemImage: "figure.strengthtraining.traditional", color: .green) {
            send(.navigationButtonTapped)
        }
    }
    
    private var weightLiftingGoalsContent: some View {
        VStack {
            titleContainerView
            Divider()
            Spacer().frame(height: 10)
            ForEach(store.data) { item in
                weightLiftingScore(item.movement.title, "\(item.goal)", "\(item.latestResult)")
                Divider().padding(.horizontal, 20)
            }
            Spacer()
            
//            weightLiftingScore("Clean & Jerk", "120")
//            Divider().padding(.horizontal, 20)
//            weightLiftingScore("Snatch", "100")
//            Divider().padding(.horizontal, 20)
//            weightLiftingScore("OverheadSquat ", "110")
//            Divider().padding(.horizontal, 20)
//            weightLiftingScore("Power Clean", "90")
//            Divider().padding(.horizontal, 20)
//            weightLiftingScore("Squat Clean", "120")
//            Divider().padding(.horizontal, 20)
//            weightLiftingScore("Split Jerk", "125")
//            Spacer()
        }
    }
    
    private var titleContainerView: some View {
        HStack {
            titleView("Exercise")
            Spacer()
            titleView("Goal")
            Spacer()
            titleView("Result")
         }
    }
    
    private func titleView(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 14, weight: .bold, design: .monospaced))
    }
    
    private func weightLiftingScore(_ title: String, _ goal: String, _ value: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 14, weight: .regular, design: .monospaced))
            Spacer()
            Text("\(goal) kg")
                .font(.system(size: 14, weight: .semibold, design: .monospaced))
            Spacer()
            Text("\(value) kg")
                .font(.system(size: 14, weight: .semibold, design: .monospaced))
        }
    }
    
    private var setYourGoalsButton: some View {
        Button {
            send(.navigationButtonTapped)
        } label: {
            Text("Set your goals")
                .foregroundStyle(.red)
        }
    }
    
    private func test(_ data: [WeightLiftingMeasurement]) -> some View {
        ForEach(data) { item in
            HStack {
                Text(item.name.rawValue)
                Spacer()
                Text("\(item.value) kg")
            }
        }
    }
    
}

#Preview {
    WeightLiftingStatsView(store: Store(initialState: WeightLiftingStatsFeature.State(), reducer: {
        WeightLiftingStatsFeature(service: DefaultWeightLiftingStatsServices())
    }))
}
