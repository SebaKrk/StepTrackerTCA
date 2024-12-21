//
//  DashboardView.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 21/12/2024.
//

import ComposableArchitecture
import SwiftUI

@ViewAction(for: DashboardFeature.self)
struct DashboardView: View {
    
    // MARK: - Properties
    
    var store: StoreOf<DashboardFeature>
    
    // MARK: - View
    
    var body: some View {
        NavigationStack {
            Text("Dashboard")
                .navigationTitle("Dashboard")
        }
        .onAppear {
            send(.viewDidAppear)
        }
    }
    
}

#Preview {
    DashboardView(store: Store(initialState: DashboardFeature.State(), reducer: {
        DashboardFeature()
    }))
}
