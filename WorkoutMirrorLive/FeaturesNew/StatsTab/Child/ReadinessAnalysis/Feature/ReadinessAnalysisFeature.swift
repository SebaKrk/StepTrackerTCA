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
                
            case .internal(.startAnalysis):
                return .run { send in
                    await dataAnalyzerClient.startAnalysis()
                }
                
            case .internal(.translateConfiguration):
                if state.configuration == nil {
                    state.configuration = TranslationSession.Configuration(
                        source: Locale.Language(identifier: "en"),
                        target: Locale.Language(identifier: "pl")
                    )
                } else {
                    state.configuration?.invalidate()
                }
                
                return .send(.internal(.triggerTranslation))
                
            case .internal(.triggerTranslation):
                state.translate.toggle()
                return .none
                
                // MARK: - View Actions
                
            case .view(.onAppear):
                return .send(.internal(.startAnalysis))
                
            case .view(.checkmarkButtonTapped):
                return .run { send in
                    await self.dismiss()
                }
                
            case let .view(.translateButtonTapped(message)):
                state.analysisText = message
                return .send(.internal(.translateConfiguration))
                
            case let .view(.translateMessage(message)):
                state.translatedText = message
                return .none

            }
        }
        ._printChanges()
    }
}

// MARK: - Action

extension ReadinessAnalysisFeature {
    @CasePathable
    enum Action: ViewAction {
        
        case `internal`(Internal)
        
        enum Internal {
            /// Triggers the AI analysis via client
            case startAnalysis
            
            ///
            case translateConfiguration
            
            ///
            case triggerTranslation
        }
        
        case view(View)
        
        enum View {
            /// View appeared - trigger AI analysis
            case onAppear
            
            /// User tapped checkmark to dismiss
            case checkmarkButtonTapped
            
            ///
            case translateButtonTapped(String)
            
            ///
            case translateMessage(String)
        }
    }
}

// MARK: - State

extension ReadinessAnalysisFeature {
    
    @ObservableState
    struct State: Equatable {
        
        /// Shared color state used for gradient backgrounds based on readiness level
        @Shared(.inMemory(.readinessLevelColor))
        var color: Color = .clear
        
        ///
        var analysisText: String = ""
        
        ///
        var configuration: TranslationSession.Configuration? = nil
        
        ///
        var translatedText: String? = ""
        
        ///
        var translate: Bool = false
        
        let fakeMessage = """
            Based on the latest health metrics:

            - **Resting Heart Rate:** 56 bpm is within the normal range, indicating good recovery.
            - **HRV:** 95 ms is above baseline, suggesting excellent autonomic balance and recovery.
            - **Sleep:** 7.5 hours is optimal for recovery, providing a strong foundation for overall readiness.
            - **Activity:** 750 kcal is within the normal range, showing that you've had a balanced level of activity without overexertion.

            **Overall Assessment:**
            - **Training Readiness Score:** 75
            - **Readiness Level:** Good Readiness

            **Recommendation:**
            ✅ Should you train today? YES
            - Recommended activity level: Normal training intensity and volume appropriate
            - Guidance: Continue with your routine workouts, as your body is well-recovered and ready for standard workouts.
            """
    }
}

