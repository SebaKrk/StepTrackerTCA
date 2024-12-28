//
//  HealthKitPermissionPrimingView.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 28/12/2024.
//

import ComposableArchitecture
import SwiftUI

@ViewAction(for: HealthKitPermissionFeature.self)
struct HealthKitPermissionPrimingView: View {
    
    // MARK: - Properties
    
    @Bindable var store: StoreOf<HealthKitPermissionFeature>
    
    // MARK: - View
    
    var body: some View {
        Text("Hello World")
            .onAppear {
                send(.viewDidAppear)
            }
    }
}
