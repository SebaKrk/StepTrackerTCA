//
//  ActivityDetailsView.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 12/01/2025.
//

import ComposableArchitecture
import SwiftUI

@ViewAction(for: ActivityDetailsFeature.self)
struct ActivityDetailsView: View {
    
    // MARK: - Properties
    
    @Bindable var store: StoreOf<ActivityDetailsFeature>
    
    // MARK: - View
    
    var body: some View {
        VStack {
            Text("ActivityDetailsView")
            Text("\(store.workout.kcal) kcal")
        }
        .onAppear {
            send(.viewDidAppear)
        }
    }
    
}
