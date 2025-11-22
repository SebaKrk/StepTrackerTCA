//
//  ReadinessAnalysisView.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 15/11/2025.
//

import ComposableArchitecture
import SwiftUI
import Translation

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
                        
                    case .streaming(let partialText):
                        aiResponseView(partialText, isStreaming: true)
                        
                    case .completed(let message):
                        if let translatedText = store.translatedText,
                           !translatedText.isEmpty,
                           store.translate {
                            aiResponseView(translatedText, isStreaming: false)
                        } else {
                            aiResponseView(message, isStreaming: false)
                        }
                        
                    case .mockResponse(let fakeMessage):
                        if let translatedText = store.translatedText,
                           !translatedText.isEmpty,
                           store.translate {
                            mockResponseView(translatedText)
                        } else {
                            mockResponseView(fakeMessage)
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
                if store.translate {
                    do {
                        let textToTranslate = getTextToTranslate()
                        guard !textToTranslate.isEmpty else { return }
                        
                        let response = try await session.translate(textToTranslate)
                        send(.translateMessage(response.targetText))
                    } catch {
                        // Handle translation errors
                    }
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
    
    private func aiResponseView(_ message: String, isStreaming: Bool) -> some View {
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
    
    private func mockResponseView(_ message: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "apple.intelligence")
                    .foregroundStyle(store.color.opacity(0.6))
                
                Text("AI Coach")
                    .font(.headline)
                    .foregroundStyle(store.color.opacity(0.6))
                
                // Badge indicating mock data
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
                let message = getTextToTranslate()
                send(.translateButtonTapped(message))
            } label: {
                Image(systemName: "translate")
            }
            .disabled(getTextToTranslate().isEmpty)
        }
    }
    
    // MARK: - Helpers
    
    private func getTextToTranslate() -> String {
        switch store.viewState {
        case .completed(let text), .mockResponse(let text):
            return text
        default:
            return ""
        }
    }
}

// MARK: - Preview

#Preview("AI Available - Streaming") {
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

#Preview("AI Unavailable - Mock Response") {
    if #available(iOS 26, *) {
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
}

#Preview("Error State") {
    if #available(iOS 26, *) {
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
}
