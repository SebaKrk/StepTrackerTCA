//
//  PersonDataView.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 23/01/2025.
//

import ComposableArchitecture
import SwiftUI

@ViewAction(for: PersonDataFeature.self)
struct PersonDataView: View {
    
    // MARK: - Properties
    
    @Bindable var store: StoreOf<PersonDataFeature>
    
    // MARK: - View
    
    var body: some View {
        personDataBody
    }
    
    // MARK: - Subview
    
    private var personDataBody: some View {
        ScrollView {
            Text("PersonDataView")
        }
        .navigationTitle("Person Data")
        .onAppear {
            send(.viewDidAppear)
        }
    }
}
