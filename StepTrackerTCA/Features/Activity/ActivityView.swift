//
//  ActivityView.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 12/01/2025.
//

import ComposableArchitecture
import SwiftUI


@ViewAction(for: ActivityFeature.self)
struct ActivityView: View {
    
    // MARK: - Properties
    
    var store: StoreOf<ActivityFeature>
    
    // MARK: - View
    
    public var body: some View {
        Text("Activity")
            .onAppear {
                send(.viewDidAppear)
            }
    }
    
}
