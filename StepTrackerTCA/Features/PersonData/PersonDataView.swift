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
            .onAppear {
                send(.viewDidAppear)
            }
    }
    
    // MARK: - Subview
    
    private var personDataBody: some View {
        NavigationStack {
            ScrollView {
                Text("Person data records")
                    
            }
            .navigationTitle("Person records")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
}
