//
//  AddMeasurementView.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 18/02/2025.
//

import ComposableArchitecture
import SwiftUI

@ViewAction(for: AddMeasurementFeature.self)
struct AddMeasurementView: View {
    
    // MARK: - Properties
    
    @Bindable var store: StoreOf<AddMeasurementFeature>
    
    // MARK: - View
    
    var body: some View {
        Text("AddMeasurementFeature")
    }
    
}
