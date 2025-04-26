//
//  HeartRateDetailsView.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 25/04/2025.
//

import ComposableArchitecture
import SwiftUI

@ViewAction(for: HeartRateDetailsFeature.self)
struct HeartRateDetailsView: View {
    
    // MARK: - Properties
    
    @Bindable var store: StoreOf<HeartRateDetailsFeature>
    
    // MARK: - View
    
    var body: some View {
        List(store.sample, id: \.startDate) { sample in
            HStack {
                Text(sample.startDate, style: .time)
                Spacer()
                let bpm = sample.quantity.doubleValue(
                    for: .count().unitDivided(by: .minute())
                )
                Text("\(Int(bpm)) BPM")
            }
        }
        .navigationTitle("Heart Rate Details")
        .onAppear {
            send(.viewDidAppear)
        }
    }
       
}

 
