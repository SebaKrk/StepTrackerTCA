//
//  SummaryView.swift
//  MyFitnessJournal Watch App
//
//  Created by Sebastian Sciuba on 19/05/2025.
//

import ComposableArchitecture
import SwiftUI

@ViewAction(for: SummaryFeature.self)
struct SummaryView: View {
    
    // MARK: - Properties
    
    @Bindable var store: StoreOf<SummaryFeature>
    
    // MARK: - View
    
    var body: some View {
        ScrollView {
            Text("SummaryFeature")
            Spacer().frame(height: 100)
            doneButton
        }
    }
    
    private var doneButton: some View {
        Button("Done") {
            send(.doneButtonPressed)
        }
    }
    
}
