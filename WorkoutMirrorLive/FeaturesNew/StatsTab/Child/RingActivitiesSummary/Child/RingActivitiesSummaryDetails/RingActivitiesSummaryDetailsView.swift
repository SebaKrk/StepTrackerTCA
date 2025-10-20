//
//  RingActivitiesSummaryDetailsView.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 19/10/2025.
//

import ComposableArchitecture
import SharedModels
import SwiftUI

@ViewAction(for: RingActivitiesSummaryDetailsFeature.self)
struct RingActivitiesSummaryDetailsView: View {
    
    // MARK: - Properties
    
    @Bindable var store: StoreOf<RingActivitiesSummaryDetailsFeature>
    
    // MARK: - Body
    
    var body: some View {
        Text("RingActivitiesSummaryDetailsFeature")
            .navigationTitle("Activities Details")
    }
    
}
