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
import FoundationModels

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
                state.coachMessage = nil
                state.mockMessage = ""
                state.isMockResponse = false
                
                return .run { send in
                    do {
                        for try await partial in try await dataAnalyzerClient.streamAnalysis() {
                            await send(.internal(.partialReceived(partial)))
                        }
                        await send(.internal(.analysisCompleted))
                    } catch {
                        await send(.internal(.analysisFailed(error.localizedDescription)))
                    }
                }
                
            case .internal(.partialReceived(let partial)):
                state.viewState = .streaming
                state.coachMessage = partial
                return .none
                
            case .internal(.analysisCompleted):
                state.viewState = .completed
                return .none
                
                // MARK: - Unavailable & MOCK
                
            case .internal(.aiUnavailable):
                state.viewState = .thinking
                state.coachMessage = nil
                state.mockMessage = ""
                state.isMockResponse = true
                
                return .run { send in
                    do {
                        // Mock uses regular String stream (no AI required!)
                        for await partial in try await dataAnalyzerClient.streamMockAnalysis() {
                            await send(.internal(.mockPartialReceived(partial)))
                        }
                        await send(.internal(.mockCompleted))
                    } catch {
                        await send(.internal(.analysisFailed(error.localizedDescription)))
                    }
                }
                
            case .internal(.mockPartialReceived(let text)):
                state.viewState = .streaming
                state.mockMessage = text
                return .none
                
            case .internal(.mockCompleted):
                state.viewState = .mockResponse
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
                return .run { _ in
                    await self.dismiss()
                }
                
            case .view(.translateButtonTapped(let message)):
                return .send(.internal(.translateConfiguration))
                
            case .view(.translateMessage(let message)):
                state.translatedText = message
                
                return .run { send in
                    let words = message.split(separator: " ")
                    var accumulated = ""
                    
                    for word in words {
                        accumulated += (accumulated.isEmpty ? "" : " ") + word
                        await send(.internal(.partialTranslationReceived(accumulated)))
                        try? await Task.sleep(nanoseconds: 50_000_000)
                    }
                    
                    await send(.internal(.translationCompleted(message)))
                }
            }
        }
        ._printChanges()
    }
}
