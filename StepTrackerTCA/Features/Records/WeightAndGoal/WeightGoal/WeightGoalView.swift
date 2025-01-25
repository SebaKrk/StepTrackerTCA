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
        VStack {
            HStack {
                Group {
                    Label("Goal", systemImage: "trophy")
                    Spacer()
                    actionButton()
                }
                .foregroundStyle(.green)
                .bold()
            }
            Divider()
        }
    }
    
    private func weightGoalContent(_ data: HealthData?) -> some View {
        VStack {
            Spacer()
            HStack {
                VStack(alignment: .leading) {
                    Text("Weight Goal")
                        .foregroundStyle(.secondary)
                    if let data {
                        Text("\(data.value, format: .number.precision(.fractionLength(1))) kg")
                            .font(.largeTitle)
                            .bold()
                    } else {
                        setYourGoalButton()
                    }
                }
                Spacer()
            }
            Spacer()
            weightGoalTitleFooter(data)
        }
    }
    
    private func weightGoalTitleFooter( _ data: HealthData?) -> some View {
        HStack {
            Spacer()
            if let data {
                Text("\(data.date, format: .dateTime.month(.defaultDigits).day().year(.twoDigits))")
                    .foregroundStyle(.green)
                    .font(.caption)
                    .bold()
            }
        }
    }
    
    private func actionButton() -> some View {
        Button {
            send(.navigationButtonTapped)
        } label: {
            Image(systemName: "chevron.right")
                .foregroundStyle(.green)
        }
    }
    
    private func setYourGoalButton() -> some View {
        Button {
            send(.navigationButtonTapped)
        } label: {
            Text("Set your goal")
                .foregroundStyle(.red)
                .font(.title3)
        }
    }
}

#Preview {
    let weightGoal = HealthData(date: .now, value: 95)
    NavigationStack {
        WeightGoalView(store: Store(initialState: WeightGoalFeature.State(weightGoal: weightGoal), reducer: {
            WeightGoalFeature()
        }))
    }
}

