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
            .sheet(item: $store.scope(state: \.destination?.detailItem, action: \.destination.detailItem), content: { store in
                SetWeightGoalView(store: store)
            })
            .onAppear {
                send(.viewDidAppear)
            }
    }
    
    // MARK: - Subview
    
    private var weightGoalBody: some View {
        GroupBox {
            Button {
                send(.testButtonTapped)
            } label: {
                VStack {
                    Spacer()
                    Text("Current Weight Goal")
                    Spacer()
                }
            }
        }
        .frame(width: 200, height: 200)
    }
    
}
