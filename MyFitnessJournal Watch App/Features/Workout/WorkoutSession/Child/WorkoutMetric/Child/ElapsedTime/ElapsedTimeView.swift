//
//  ElapsedTimeView.swift
//  MyFitnessJournal Watch App
//
//  Created by Sebastian Sciuba on 22/05/2025.
//

import ComposableArchitecture
import SwiftUI

struct ElapsedTimeView: View {
    
    // MARK: - Properties
    
    @Bindable var store: StoreOf<ElapsedTimeFeature>
    @State private var timeFormatter = ElapsedTimeFormatter()
    
    // MARK: - View
    
    var body: some View {
        Text(NSNumber(value: store.elapsedTime), formatter: timeFormatter)
            .fontWeight(.semibold)
            .onChange(of: store.showSubseconds) {
                timeFormatter.showSubseconds = store.showSubseconds
            }
    }
    
}
