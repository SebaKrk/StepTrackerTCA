//
//  StepPieWidgetView.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 16/01/2025.
//

import ComposableArchitecture
import SwiftUI

@ViewAction(for: StepPieWidgetFeature.self)
struct StepPieWidgetView: View {
    
    // MARK: - Properties
    
    @Bindable var store: StoreOf<StepPieWidgetFeature>
    
    // MARK: - View
    
    var body: some View {
        Text("StepPieWidgetFeature")
            .onAppear {
                send(.viewDidAppear)
            }
    }
    
}
