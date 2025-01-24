//
//  CurrentWeightView.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 24/01/2025.
//

import ComposableArchitecture
import SwiftUI

@ViewAction(for: CurrentWeightFeature.self)
struct CurrentWeightView: View {
    
    // MARK: - Properties
    
    @Bindable var store: StoreOf<CurrentWeightFeature>
    
    // MARK: - View
    
    var body: some View {
        currentWeightBody
            .onAppear {
                send(.viewDidAppear)
            }
    }
    
    // MARK: - Subview
    
    private var currentWeightBody: some View {
        Text("Current Weight Body")
    }
    
}
