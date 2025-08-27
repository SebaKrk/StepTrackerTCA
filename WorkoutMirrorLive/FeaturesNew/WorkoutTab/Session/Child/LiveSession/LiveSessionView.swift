//
//  LiveSessionView.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 27/08/2025.
//

import ComposableArchitecture
import SwiftUI

@ViewAction(for: LiveSessionFeature.self)
struct LiveSessionView: View {
    
    // MARK: - Properties
    @Bindable var store: StoreOf<LiveSessionFeature>
    
    // MARK: - Body
    
    var body: some View {
//        VStack {
//            Spacer()
//            Text("LiveSessionView")
//            Spacer()
//        }
        List(0..<100) { i in
            Text("activitie \(i)")
        }
    }
}

#Preview("LiveSessionFeature") {
    NavigationStack {
        LiveSessionView(
            store: Store(initialState: LiveSessionFeature.State(),
                         reducer: { LiveSessionFeature() })
        )
    }
}



    
