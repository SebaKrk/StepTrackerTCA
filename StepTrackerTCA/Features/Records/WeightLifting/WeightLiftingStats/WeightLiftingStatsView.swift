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
            weightLiftingGoalsWidget
        }
        .onAppear {
            send(.viewDidAppear)
        }
        .sheet(item: $store.scope(state: \.destination?.openGoal, action: \.destination.openGoal), content: { store in
            SetEditGoalView(store: store)
                .presentationDetents([.medium, .large])
        })
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
            if store.data.isEmpty {
                unavailableViewGoalsView
            } else {
                weightLiftingGoalsContent
            }
        } label: {
            weightLiftingGoalsTitleHeader
        }
        .frame(minHeight: 200)
    }
    
    private var unavailableViewGoalsView: some View {
        ContentUnavailableView {
            Label {
                Text("No Training Goal Set")
            } icon: {
                Image(systemName: "list.bullet")
            }
        } description: {
            Text("You haven't set a goal yet.\n Add a new goal to track your progress.")
        } actions: {
            Button {
                send(.openSetEditSheet)
            } label: {
                Label("Add New Goal", systemImage: "plus.circle")
            }
            .foregroundColor(.green)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .foregroundStyle(.secondary)
        .padding()
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
                Divider()
            }
            Spacer()
        }
    }
    
    private var titleContainerView: some View {
        GeometryReader { geometry in
            HStack {
                titleView("Exercise")
                    .frame(width: geometry.size.width * 0.4, alignment: .leading)
                titleView("Goal")
                    .frame(width: geometry.size.width * 0.3, alignment: .center)
                titleView("Result")
                    .frame(width: geometry.size.width * 0.3, alignment: .trailing)
                    .padding(.trailing, 5)
            }
            .frame(width: geometry.size.width)
        }
        .frame(height: 20)
    }
    
    private func titleView(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 14, weight: .bold, design: .monospaced))
    }
    
    private func weightLiftingScore(_ title: String, _ goal: String, _ value: String) -> some View {
        GeometryReader { geometry in
            HStack {
                Text(title)
                    .font(.system(size: 14, weight: .regular, design: .monospaced))
                    .frame(width: geometry.size.width * 0.4, alignment: .leading)
                
                Text("\(goal) kg")
                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                    .frame(width: geometry.size.width * 0.3, alignment: .center)
                
                Spacer(minLength: 5)
                
                Text("\(value) kg")
                    .font(.system(size: 14, weight: .regular, design: .monospaced))
                    .frame(width: geometry.size.width * 0.28, alignment: .trailing)
                    .padding(.trailing, 10)
            }
        }
        .frame(height: 20)
    }
    
    private var setYourGoalsButton: some View {
        Button {
            send(.navigationButtonTapped)
        } label: {
            Text("Set your goals")
                .foregroundStyle(.red)
        }
    }
    
}

#Preview {
    WeightLiftingStatsView(store: Store(initialState: WeightLiftingStatsFeature.State(), reducer: {
        WeightLiftingStatsFeature(service: DefaultWeightLiftingStatsServices())
    }))
}
