//
//  ReadinessAnalysisFeature+Action.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 22/11/2025.
//

import ComposableArchitecture
import Foundation
import FoundationModels

extension ReadinessAnalysisFeature {
    
    @CasePathable
    enum Action: ViewAction {
        
        case `internal`(Internal)
        
        enum Internal {
            /// Check if AI is available on device
            case checkAvailability
            
            /// AI is available - start streaming analysis
            case aiAvailable
            
            /// Received partial message from AI stream (String.PartiallyGenerated)
            case partialReceived(String.PartiallyGenerated)
            
            /// Analysis completed successfully
            case analysisCompleted
            
            /// AI unavailable - show mock response
            case aiUnavailable
            
            /// Received partial mock message from stream (regular String)
            case mockPartialReceived(String)
            
            /// Mock analysis completed
            case mockCompleted
            
            /// Analysis failed with error
            case analysisFailed(String)
            
            /// Configure translation session
            case translateConfiguration
            
            /// Trigger translation toggle
            case triggerTranslation
            
            /// Start streaming translation
            case startStreamingTranslation
            
            /// Received partial translation during streaming
            case partialTranslationReceived(String)
            
            /// Translation completed with final text
            case translationCompleted(String)
        }
        
        case view(View)
        
        enum View {
            /// View appeared - trigger AI analysis
            case onAppear
            
            /// User tapped checkmark to dismiss
            case checkmarkButtonTapped
            
            /// User tapped translate button with message to translate
            case translateButtonTapped(String)
            
            /// Translated message received
            case translateMessage(String)
        }
    }
}
