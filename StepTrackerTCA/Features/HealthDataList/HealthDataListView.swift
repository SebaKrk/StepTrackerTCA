//
//  HealthDataListView.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 22/12/2024.
//

import ComposableArchitecture
import SwiftUI

struct HealthDataListView: View {
    
    // MARK: - Properties
    
    var store: StoreOf<HealthDataListFeature>
    
    // MARK: - View
    
    var body: some View {
        VStack {
            Text("HealthDataListView")
            Text(store.healthMetric.title)
        }
    }
    
}
