//
//  StepWidgetView.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 16/01/2025.
//

import ComposableArchitecture
import SwiftUI

@ViewAction(for: StepWidgetFeature.self)
struct StepWidgetView: View {
    
    // MARK: - Properties
    
    @Bindable var store: StoreOf<StepWidgetFeature>
    
    // MARK: - View
    
    var body: some View {
        Text("StepWidgetFeature")
            .onAppear {
                send(.viewDidAppear)
            }
    }
    
}
