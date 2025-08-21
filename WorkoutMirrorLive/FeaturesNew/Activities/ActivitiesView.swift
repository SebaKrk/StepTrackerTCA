//
//  ActivitiesView.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 20/08/2025.
//

import ComposableArchitecture
import SwiftUI

@ViewAction(for: ActivitiesFeature.self)
struct ActivitiesView: View {
    
    // MARK: - Properties
    @Bindable var store: StoreOf<ActivitiesFeature>
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            List(0..<100) { i in
                Text("activitie \(i)")
            }
            .navigationTitle("ActivitiesFeature")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
