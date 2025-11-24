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

extension ReadinessAnalysisFeature {
    
    @ObservableState
    struct State: Equatable {
        
        /// Shared color state used for gradient backgrounds based on readiness level
        @Shared(.inMemory(.readinessLevelColor))
        var color: Color = .clear
        
        /// Current view state (idle, thinking, streaming, completed, mock, failed)
        var viewState: ReadinessViewState = .idle
        
        /// Translation session configuration
        var configuration: TranslationSession.Configuration? = nil
        
        /// Translated text result
        var translatedText: String? = ""
        
        /// Translation toggle
        var translate: Bool = false
        
        /// Streaming translation state
        var isTranslating: Bool = false
        
        /// Partial translation during streaming
        var partialTranslation: String = ""
    }
}
