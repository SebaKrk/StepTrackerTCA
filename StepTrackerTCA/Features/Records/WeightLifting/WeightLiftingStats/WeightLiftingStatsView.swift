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
        WidgetHeaderView(title: "WeightLifting Stats", systemImage: "figure.strengthtraining.traditional", color: .green) {
            send(.navigationButtonTapped)
        }
    }
    
    private var weightLiftingGoalsContent: some View {
        VStack {
            Spacer()
            WidgetBodyContentWithButton(title: "WeightLifting Goals",
                              color: .green) {
                AnyView(setYourGoalsButton)
                
            }
            Spacer()
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
    
}

#Preview {
    WeightLiftingStatsView(store: Store(initialState: WeightLiftingStatsFeature.State(), reducer: {
        WeightLiftingStatsFeature(service: DefaultWeightLiftingStatsServices())
    }))
}
