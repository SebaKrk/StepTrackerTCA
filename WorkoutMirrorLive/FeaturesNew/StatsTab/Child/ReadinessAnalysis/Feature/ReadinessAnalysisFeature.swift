//
//  ReadinessAnalysisFeature.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 15/11/2025.
//

import ComposableArchitecture
import SwiftUI
import SharedModels
import Translation

@Reducer
struct ReadinessAnalysisFeature {
    
    // MARK: - Dependency
    
    @Dependency(\.dismiss) var dismiss
    @Dependency(\.dataAnalyzerClient) var dataAnalyzerClient
    
    // MARK: - Reducer
    
    var body: some Reducer<State, Action> {
        Reduce<State, Action> { state, action in
            switch action {
                // MARK: - Internal Actions
                
            case .internal(.checkAvailability):
                return .run { send in
                    do {
                        let available = try await dataAnalyzerClient.isAvailable()
                        
                        if available {
                            await send(.internal(.aiAvailable))
                        } else {
                            await send(.internal(.aiUnavailable))
                        }
                    } catch {
                        await send(.internal(.aiUnavailable))
                    }
                }
                
            case .internal(.aiAvailable):
                state.viewState = .thinking
                
                return .run { send in
                    do {
                        for await partial in try await dataAnalyzerClient.streamAnalysis() {
                            await send(.internal(.partialReceived(partial)))
                        }
                        await send(.internal(.analysisCompleted))
                    } catch {
                        await send(.internal(.analysisFailed(error.localizedDescription)))
                    }
                }
                
            case .internal(.partialReceived(let text)):
                state.viewState = .streaming(text)
                return .none
                
            case .internal(.analysisCompleted):
                if case .streaming(let text) = state.viewState {
                    state.viewState = .completed(text)
                }
                return .none
                
                // MARK: - Unavailable & MOCK
                
            case .internal(.aiUnavailable):
                state.viewState = .thinking
                
                return .run { send in
                    do {
                        for await partial in try await dataAnalyzerClient.streamAnalysis() {
                            await send(.internal(.mockPartialReceived(partial)))
                        }
                        await send(.internal(.mockCompleted))
                    } catch {
                        await send(.internal(.analysisFailed(error.localizedDescription)))
                    }
                }
                
            case .internal(.mockPartialReceived(let text)):
                state.viewState = .streaming(text)
                return .none
                
            case .internal(.mockCompleted):
                if case .streaming(let text) = state.viewState {
                    state.viewState = .mockResponse(text)
                }
                return .none
                
                // MARK: - Failed
                
            case .internal(.analysisFailed(let error)):
                state.viewState = .failed(error)
                return .none
                
                // MARK: - Translation
                
            case .internal(.translateConfiguration):
                if state.configuration == nil {
                    state.configuration = TranslationSession.Configuration(
                        source: Locale.Language(identifier: "en"),
                        target: Locale.Language(identifier: "pl")
                    )
                }
                
                return .send(.internal(.startStreamingTranslation))
                
            case .internal(.triggerTranslation):
                state.translate.toggle()
                return .none
                
            case .internal(.startStreamingTranslation):
                state.isTranslating = true
                state.partialTranslation = ""
                state.translate = true
                return .none
                
            case .internal(.partialTranslationReceived(let partial)):
                state.partialTranslation = partial
                return .none
                
            case .internal(.translationCompleted(let final)):
                state.translatedText = final
                state.isTranslating = false
                return .none
                
                // MARK: - View Actions
                
            case .view(.onAppear):
                return .send(.internal(.checkAvailability))
                
            case .view(.checkmarkButtonTapped):
                return .run { send in
                    await self.dismiss()
                }
                
            case .view(.translateButtonTapped(let message)):
                return .send(.internal(.translateConfiguration))
                
            case .view(.translateMessage(let message)):
                state.translatedText = message
                
                // Simulate streaming effect
                return .run { send in
                    let words = message.split(separator: " ")
                    var accumulated = ""
                    
                    for word in words {
                        accumulated += (accumulated.isEmpty ? "" : " ") + word
                        await send(.internal(.partialTranslationReceived(accumulated)))
                        try? await Task.sleep(nanoseconds: 50_000_000) // 50ms delay
                    }
                    
                    await send(.internal(.translationCompleted(message)))
                }
            }
        }
        ._printChanges()
    }
    
}
