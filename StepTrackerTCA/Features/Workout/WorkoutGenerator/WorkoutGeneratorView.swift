//
//  WorkoutGeneratorView.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 27/06/2025.
//

import ComposableArchitecture
import SwiftUI
import PhotosUI

@ViewAction(for: WorkoutGeneratorFeature.self)
struct WorkoutGeneratorView: View {
    
    @Bindable var store: StoreOf<WorkoutGeneratorFeature>
    
    var body: some View {
        ScrollView {
            Text(store.recognizedText)
                .textSelection(.enabled)/
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .padding()
    }
    
}
