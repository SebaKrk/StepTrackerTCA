//
//  ReadinessAnalysisFeature+State.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 22/11/2025.
//

import ComposableArchitecture
import SwiftUI
import SharedModels
import Translation
import FoundationModels

extension ReadinessAnalysisFeature {
    
    @ObservableState
    struct State: Equatable {
        
        /// Shared color state used for gradient backgrounds based on readiness level
        @Shared(.inMemory(.readinessLevelColor))
        var color: Color = .gray
        
        /// Current view state (idle, thinking, streaming, completed, mock, failed)
        var viewState: ReadinessViewState = .idle
        
        /// Partial response from AI model during streaming (for real AI)
        var coachMessage: String.PartiallyGenerated?
        
        /// Mock message for when AI is unavailable (regular String)
        var mockMessage: String = ""
        
        /// Flag indicating if current response is mock (AI unavailable)
        var isMockResponse: Bool = false
        
        /// Translation session configuration
        var configuration: TranslationSession.Configuration? = nil
        
        /// Translated text result
        var translatedText: String? = nil
        
        /// Translation toggle
        var translate: Bool = false
        
        /// Streaming translation state
        var isTranslating: Bool = false
        
        /// Partial translation during streaming
        var partialTranslation: String = ""
        
        // MARK: - Computed Properties
        
        /// Returns the current message as String (for translation etc.)
        /// Works for both AI (String.PartiallyGenerated) and mock (String) responses
        var currentMessage: String {
            if isMockResponse {
                return mockMessage
            } else if let message = coachMessage {
                return "\(message)"
            }
            return ""
        }
    }
}
