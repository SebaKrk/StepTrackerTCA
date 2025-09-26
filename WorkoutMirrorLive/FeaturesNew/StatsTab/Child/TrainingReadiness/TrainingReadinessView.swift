//
//  TrainingReadinessView.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 26/09/2025.
//

import ComposableArchitecture
import SwiftUI

@ViewAction(for: TrainingReadinessFeature.self)
struct TrainingReadinessView: View {
    
    // MARK: - Properties
    
    @Bindable var store: StoreOf<TrainingReadinessFeature>
    
    // MARK: - View
    
    var body: some View {
        GroupBox {
            Spacer()
            Text("TrainingReadinessView")
            Spacer()
        } label: {
            HStack {
                Text("Training Readiness")
                Spacer()
                Text("Good")
            }
        }
        .padding([.leading, .trailing], 8)
        .foregroundStyle(.secondary)
        .frame(height: 75)
    }
}
