//
//  ReadinessAnalysisView.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 15/11/2025.
//

import ComposableArchitecture
import SwiftUI

@available(iOS 26, *)
@ViewAction(for: ReadinessAnalysisFeature.self)
struct ReadinessAnalysisView: View {
    
    // MARK: - Properties
    
    @Bindable var store: StoreOf<ReadinessAnalysisFeature>
    
    private var analyzer: DataAnalyzer { DataAnalyzer.shared }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    
                    if analyzer.isThinking {
                        thinkingView
                    }
                    
                    if let message = analyzer.coachMessage, !message.isEmpty {
                        aiResponseView(message)
                    }
                }
                .padding()
            }
            .toolbar {
                toolbarButton
            }
            .navigationTitle("Readiness Analysis")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                send(.onAppear)
            }
        }
    }
    
    // MARK: - Subviews
    
    private var thinkingView: some View {
        VStack(spacing: 16) {
            Image(systemName: "apple.intelligence")
                .resizable()
                .frame(width: 40, height: 40)
                .symbolEffect(.pulse, options: .repeat(.continuous))
            
            Text("Analyzing your health data...")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }
    
    private func aiResponseView(_ message: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "apple.intelligence")
                    .foregroundStyle(store.color)
                
                Text("AI Coach")
                    .font(.headline)
                    .foregroundStyle(store.color)
                
                if analyzer.isThinking {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            
            Text(.init(message))
                .font(.body)
                .tint(store.color)
                .foregroundStyle(.primary)
                .contentTransition(.interpolate)
                .animation(.easeInOut(duration: 0.8), value: message)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(store.color.opacity(0.3), lineWidth: 1)
        )
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

// MARK: - Preview

#Preview {
    if #available(iOS 26, *) {
        ReadinessAnalysisView(
            store: Store(
                initialState: ReadinessAnalysisFeature.State()
            ) {
                ReadinessAnalysisFeature()
            } withDependencies: {
                $0.dataAnalyzerClient = .previewValue
            }
        )
    }
}
