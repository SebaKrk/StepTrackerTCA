//
//  DataAnalyzerClient.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 15/11/2025.
//

import ComposableArchitecture
import Foundation
import SharedModels

#if canImport(FoundationModels)
import FoundationModels
#endif

@DependencyClient
struct DataAnalyzerClient: Sendable {
    
    /// Checks if Apple Intelligence is available on this device
    var isAvailable: @Sendable () async throws -> Bool
    
    /// Streams AI analysis with String.PartiallyGenerated for live updates (real AI)
    var streamAnalysis: @Sendable () async throws -> AsyncThrowingStream<String.PartiallyGenerated, Error>
    
    /// Streams mock analysis with regular String (no AI required)
    var streamMockAnalysis: @Sendable () async throws -> AsyncStream<String>
}

extension DependencyValues {
    var dataAnalyzerClient: DataAnalyzerClient {
        get { self[DataAnalyzerClient.self] }
        set { self[DataAnalyzerClient.self] = newValue }
    }
}

@available(iOS 26, *)
extension DataAnalyzerClient: DependencyKey {
    
    // MARK: - Live Value
    
    static let liveValue: DataAnalyzerClient = {
        @Dependency(\.trainingReadinessClient) var readinessClient
        
        let analyzer = DataAnalyzer(readinessClient: readinessClient)
        
        return DataAnalyzerClient(
            isAvailable: {
                await analyzer.available
            },
            streamAnalysis: {
                try await analyzer.streamAnalysis()
            },
            streamMockAnalysis: {
                mockStream()
            }
        )
    }()
    
    // MARK: - Mock Stream Helper (no AI required!)
    
    private static func mockStream() -> AsyncStream<String> {
        AsyncStream { continuation in
            Task {
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
                
                let words = fakeMessage.split(separator: " ")
                var accumulated = ""
                
                for word in words {
                    accumulated += (accumulated.isEmpty ? "" : " ") + word
                    continuation.yield(accumulated)
                    try? await Task.sleep(for: .milliseconds(50))
                }
                
                continuation.finish()
            }
        }
    }
    
    // MARK: - Preview Value
    
    static let previewValue = DataAnalyzerClient(
        isAvailable: { true },
        streamAnalysis: {
            AsyncThrowingStream { continuation in
                continuation.finish()
            }
        },
        streamMockAnalysis: { mockStream() }
    )
}

// MARK: - Mock Preview (AI Unavailable)

@available(iOS 26, *)
extension DataAnalyzerClient {
    static let mockUnavailable = DataAnalyzerClient(
        isAvailable: { false },
        streamAnalysis: {
            AsyncThrowingStream { continuation in
                continuation.finish()
            }
        },
        streamMockAnalysis: { mockStream() }
    )
}
