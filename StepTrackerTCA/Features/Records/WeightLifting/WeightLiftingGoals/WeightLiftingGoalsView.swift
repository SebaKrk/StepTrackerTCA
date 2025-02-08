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
        Group {
            Text("WeightLiftingGoalsFeature")
        }
        .onAppear {
            send(.viewDidAppear)
        }
        .navigationDestination(
            item: $store.scope(
                state: \.destination?.open,
                action: \.destination.open)) { store in
                    // do zmiany
                    SetWeightGoalView(store: store)
                }
    }
    
}

#Preview {
    WeightLiftingGoalsView(store: Store(initialState: WeightLiftingGoalsFeature.State(), reducer: {
        WeightLiftingGoalsFeature(service: DefaultWeightLiftingGoalsServices())
    }))
}
