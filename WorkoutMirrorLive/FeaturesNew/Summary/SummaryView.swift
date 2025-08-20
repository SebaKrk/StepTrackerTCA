//
//  SummaryView.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 20/08/2025.
//

import ComposableArchitecture
import SwiftUI

@ViewAction(for: SummaryFeature.self)
struct SummaryView: View {
    
    // MARK: - Properties
    @Bindable var store: StoreOf<SummaryFeature>
    
    // MARK: - Body
    
    var body: some View {
        Text("SummaryFeature")
    }
}
