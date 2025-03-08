//
//  PersonDataView.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 23/01/2025.
//

import ComposableArchitecture
import SwiftUI

@ViewAction(for: PersonDataFeature.self)
struct PersonDataView: View {
    
    // MARK: - Properties
    
    @Bindable var store: StoreOf<PersonDataFeature>
    
    // MARK: - View
    
    var body: some View {
        personDataBody
        .onAppear {
            send(.viewDidAppear)
        }
    }
    
    // MARK: - Subview
    
    private var personDataBody: some View {
        NavigationStack {
            ScrollView {
                Group {
                    HStack {
                        currentWeightView
                        weightGoalView
                    }
                    weightLiftingStatsView
                    strengthSummaryView
                }
                .padding([.leading, .trailing], 12)
            }
            .navigationTitle("Person records")
            .navigationBarTitleDisplayMode(.inline)
            .overlay(alignment: .bottomTrailing) {
                addNewRecordButton
            }
            .sheet(item: $store.scope(state: \.destination?.show, action: \.destination.show), content: { store in
                AddMeasurementView(store: store)
                    .presentationDetents([.large, .medium])
            })
        }
    }
    
    @ViewBuilder
    private var currentWeightView: some View {
        CurrentWeightView(store: store.scope(state: \.currentWeight, action: \.currentWeight))
    }
    
    @ViewBuilder
    private var weightGoalView: some View {
        WeightGoalView(store: store.scope(state: \.weightGoal, action: \.weightGoal))
    }
    
    @ViewBuilder
    private var weightLiftingStatsView: some View {
        WeightLiftingStatsView(store: store.scope(state: \.weightLiftingStats, action: \.weightLiftingStats))
    }
    
    @ViewBuilder
    private var strengthSummaryView: some View {
        StrengthSummaryView(store: store.scope(state: \.strengthSummary, action: \.strengthSummary))
    }
    
    private var addNewRecordButton: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button {
                    send(.addMetricButtonPressed)
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 15, weight: .light))
                        .frame(width: 40, height: 40)
                        .background(Circle().fill(Color.green))
                        .foregroundColor(.white)
                        .shadow(radius: 5)
                }
                .padding()
            }
        }
    }
    
}

#Preview {
    var weightData: [HealthData] = [.init(date: .now, value: 100)]
    NavigationStack {
        PersonDataView(store: Store(initialState: PersonDataFeature.State(weightData: weightData), reducer: {
            PersonDataFeature(service: DefaultPersonDataFeatureService())
        }))
    }
}
