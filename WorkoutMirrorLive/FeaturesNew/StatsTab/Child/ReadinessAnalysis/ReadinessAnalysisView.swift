//
//  ReadinessAnalysisView.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 15/11/2025.
//

import ComposableArchitecture
import SwiftUI

@ViewAction(for: ReadinessAnalysisFeature.self)
struct ReadinessAnalysisView: View {
    
    // MARK: - Properties
    
    @Bindable var store: StoreOf<ReadinessAnalysisFeature>
    
    @Namespace var zoomTransition
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ScrollView {
//                Text(analyzer.coachMessage ?? "")
//                    .contentTransition(.interpolate)
//                    .animation(.easeInOut(duration: 0.8), value: analyzer.coachMessage)
            }
            .toolbar {
                toolbarButton
            }
            .navigationTitle("Readiness Analysis")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    @ToolbarContentBuilder
    private var toolbarButton: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                send(.checkmarkButtonTapped)
            } label: {
                Image(systemName: "checkmark")
            }
            .buttonStyle(.glassProminent)
            .tint(store.color)
        }
    }
    
}


//if analyzer.isThinking {
//    VStack(spacing: 16) {
//        Image(systemName: "apple.intelligence")
//            .resizable()
//            .frame(width: 40, height: 40)
//            .symbolEffect(.pulse, options: .repeat(.continuous))
//
//        Text("Thinking...")
//            .font(.callout)
//    }
//    .foregroundStyle(.secondary)
//    .frame(minWidth: 200)
//}
