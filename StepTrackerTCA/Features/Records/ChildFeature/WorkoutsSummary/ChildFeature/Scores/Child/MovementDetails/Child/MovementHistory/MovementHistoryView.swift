//
//  MovementHistoryView.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 14/04/2025.
//

import ComposableArchitecture
import SwiftUI

@ViewAction(for: MovementHistoryFeature.self)
struct MovementHistoryView: View {
    
    // MARK: - Properties
    
    @Bindable var store: StoreOf<MovementHistoryFeature>
    
    // MARK: - View
    
    var body: some View {
        Text("MovementHistoryView")
    }
    
}

