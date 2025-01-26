//
//  WeightGoalView.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 24/01/2025.
//

import ComposableArchitecture
import SwiftUI

@ViewAction(for: WeightGoalFeature.self)
struct WeightGoalView: View {
    
    // MARK: - Properties
    
    @Bindable var store: StoreOf<WeightGoalFeature>
    
    // MARK: - View
    
    var body: some View {
        weightGoalBody
            .sheet(item: $store.scope(state: \.destination?.setWeightGoal, action: \.destination.setWeightGoal), content: { store in
                SetWeightGoalView(store: store)
            })
            .onAppear {
                send(.viewDidAppear)
            }
    }
    
    // MARK: - Subview
    
    private var weightGoalBody: some View {
        weightGoalWidget(store.weightGoal)
    }
    
    private func weightGoalWidget(_ data: HealthData?) -> some View {
        GroupBox {
            weightGoalContent(data)
        } label: {
            weightGoalTitleHeader(data)
        }
        .frame(minHeight: 200)
    }
    
    private func weightGoalTitleHeader( _ data: HealthData?) -> some View {
        WidgetHeaderView(title: "Goal", systemImage: "trophy", color: .green) {
            send(.navigationButtonTapped)
        }
    }
    
    private func weightGoalContent(_ data: HealthData?) -> some View {
        VStack {
            Spacer()
            WidgetBodyContentWithButton(title: "Weight Goal",
                              value: data?.value,
                              color: .green) {
                AnyView(setYourGoalButton())
            }
            Spacer()
            weightGoalTitleFooter(data)
        }
    }
    
    @ViewBuilder
    private func weightGoalTitleFooter( _ data: HealthData?) -> some View {
        if let date = data?.date {
            WidgetTitleFooterDate(date: date, color: .green)
        }
    }
    
    private func setYourGoalButton() -> some View {
        Button {
            send(.navigationButtonTapped)
        } label: {
            Text("Set your goal")
                .foregroundStyle(.red)
        }
    }
}

#Preview {
    let weightGoal = HealthData(date: .now, value: 95)
    NavigationStack {
        WeightGoalView(store: Store(initialState: WeightGoalFeature.State(weightGoal: weightGoal), reducer: {
            WeightGoalFeature(service: DefaultWeightGoalServices())
        }))
    }
}

