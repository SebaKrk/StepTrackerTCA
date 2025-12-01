//
//  ReadinessAnalysisView.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 15/11/2025.
//

import ComposableArchitecture
import SwiftUI
import Translation
import FoundationModels

@available(iOS 26, *)
@ViewAction(for: ReadinessAnalysisFeature.self)
struct ReadinessAnalysisView: View {
    
    // MARK: - Properties
    
    @Bindable var store: StoreOf<ReadinessAnalysisFeature>
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    switch store.viewState {
                    case .idle:
                        EmptyView()
                        
                    case .thinking:
                        thinkingView
                        
                    case .streaming:
                        if store.isMockResponse {
                            // Mock: use regular String
                            aiResponseView(store.mockMessage, isStreaming: true)
                        } else {
                            // AI: use String.PartiallyGenerated
                            aiResponseViewPartial(isStreaming: true)
                        }
                        
                    case .completed:
                        if store.isTranslating {
                            translatingView(store.partialTranslation)
                        } else if let translatedText = store.translatedText,
                                  !translatedText.isEmpty,
                                  store.translate {
                            aiResponseView(translatedText, isStreaming: false, isTranslated: true)
                        } else {
                            aiResponseViewPartial(isStreaming: false)
                        }
                        
                    case .mockResponse:
                        if store.isTranslating {
                            translatingView(store.partialTranslation)
                        } else if let translatedText = store.translatedText,
                                  !translatedText.isEmpty,
                                  store.translate {
                            mockResponseView(translatedText, isTranslated: true)
                        } else {
                            mockResponseView(store.mockMessage, isTranslated: false)
                        }
                        
                    case .failed(let error):
                        errorView(error)
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
            .translationTask(store.configuration) { session in
                guard store.translate else { return }
                
                do {
                    let textToTranslate = store.currentMessage
                    guard !textToTranslate.isEmpty else { return }
                    
                    let response = try await session.translate(textToTranslate)
                    send(.translateMessage(response.targetText))
                    
                } catch {
                    // Fallback: if translation fails, simulate with original text
                    let textToTranslate = store.currentMessage
                    guard !textToTranslate.isEmpty else { return }
                    send(.translateMessage(textToTranslate))
                }
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
    
    private func translatingView(_ partialText: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "translate")
                    .foregroundStyle(store.color)
                
                Text("Translating...")
                    .font(.headline)
                    .foregroundStyle(store.color)
                
                ProgressView()
                    .scaleEffect(0.8)
            }
            
            if !partialText.isEmpty {
                Text(.init(partialText))
                    .font(.body)
                    .tint(store.color)
                    .foregroundStyle(.primary)
                    .contentTransition(.interpolate)
                    .animation(.easeInOut(duration: 0.3), value: partialText)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(store.color.opacity(0.3), lineWidth: 1)
        )
    }
    
    /// AI response view using String.PartiallyGenerated directly
    private func aiResponseViewPartial(isStreaming: Bool) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "apple.intelligence")
                    .foregroundStyle(store.color)
                
                Text("AI Coach")
                    .font(.headline)
                    .foregroundStyle(store.color)
                
                if isStreaming {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            
            if let message = store.coachMessage {
                Text(.init(message))
                    .font(.body)
                    .tint(store.color)
                    .foregroundStyle(.primary)
                    .contentTransition(.interpolate)
                    .animation(.easeInOut(duration: 0.8), value: store.coachMessage)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(store.color.opacity(0.3), lineWidth: 1)
        )
    }
    
    /// AI response view using regular String (for mock or translated)
    private func aiResponseView(_ message: String, isStreaming: Bool, isTranslated: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: isTranslated ? "translate" : "apple.intelligence")
                    .foregroundStyle(store.color)
                
                Text(isTranslated ? "AI Coach (Translated)" : "AI Coach")
                    .font(.headline)
                    .foregroundStyle(store.color)
                
                if isStreaming {
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
    
    private func mockResponseView(_ message: String, isTranslated: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: isTranslated ? "translate" : "apple.intelligence")
                    .foregroundStyle(store.color.opacity(0.6))
                
                Text(isTranslated ? "AI Coach (Translated)" : "AI Coach")
                    .font(.headline)
                    .foregroundStyle(store.color.opacity(0.6))
                
                Text("MOCK")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.orange.opacity(0.2))
                    .foregroundStyle(.orange)
                    .clipShape(Capsule())
            }
            
            Text(.init(message))
                .font(.body)
                .tint(store.color)
                .foregroundStyle(.primary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(store.color.opacity(0.2), lineWidth: 1)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.orange.opacity(0.05))
                )
        )
    }
    
    private func errorView(_ error: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .resizable()
                .frame(width: 40, height: 40)
                .foregroundStyle(.red)
            
            Text("Analysis Failed")
                .font(.headline)
            
            Text(error)
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
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
        
        ToolbarItem(placement: .topBarLeading) {
            Button {
                let message = store.currentMessage
                send(.translateButtonTapped(message))
            } label: {
                Image(systemName: "translate")
            }
            .disabled(store.currentMessage.isEmpty || store.isTranslating)
        }
    }
}

// MARK: - Preview

@available(iOS 26, *)
#Preview("AI Available - Streaming") {
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

@available(iOS 26, *)
#Preview("AI Unavailable - Mock Response") {
    ReadinessAnalysisView(
        store: Store(
            initialState: ReadinessAnalysisFeature.State()
        ) {
            ReadinessAnalysisFeature()
        } withDependencies: {
            $0.dataAnalyzerClient = .mockUnavailable
        }
    )
}

@available(iOS 26, *)
#Preview("Error State") {
    ReadinessAnalysisView(
        store: Store(
            initialState: ReadinessAnalysisFeature.State(
                viewState: .failed("Network connection lost. Please try again.")
            )
        ) {
            ReadinessAnalysisFeature()
        }
    )
}
