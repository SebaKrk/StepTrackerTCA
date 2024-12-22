//
//  AddMetricDataView.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 22/12/2024.
//

import ComposableArchitecture
import SwiftUI

@ViewAction(for: AddMetricDataFeature.self)
struct AddMetricDataView: View {
    
    // MARK: - Properties
    
    var store: StoreOf<AddMetricDataFeature>
    
    // MARK: - View
    
    var body: some View {
        Text("AddMetricDataView")
    }
    
    // MARK: - SubView
    
}
