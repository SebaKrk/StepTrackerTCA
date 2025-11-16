//
//  DataAnalyzerClient.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 15/11/2025.
//

import ComposableArchitecture
import Foundation

#if canImport(FoundationModels)
import FoundationModels
#endif

// MARK: - Client

@DependencyClient
struct DataAnalyzerClient: Sendable {
    
    /// Checks if Apple Intelligence is available on this device
    var isAvailable: @Sendable () async -> Bool = { false }
    
    /// Triggers AI analysis (streaming happens via @Observable in DataAnalyzer.shared)
    var startAnalysis: @Sendable () async -> Void = { }
}
extension DependencyValues {
    var dataAnalyzerClient: DataAnalyzerClient {
        get { self[DataAnalyzerClient.self] }
        set { self[DataAnalyzerClient.self] = newValue }
    }
}

extension DataAnalyzerClient: DependencyKey {
    static let liveValue = DataAnalyzerClient(
        isAvailable: {
            #if canImport(FoundationModels)
            if #available(iOS 26, *) {
                return await DataAnalyzer.shared.available
            }
            #endif
            return false
        },
        startAnalysis: {
            #if canImport(FoundationModels)
            if #available(iOS 26, *) {
                await DataAnalyzer.shared.analyzeHealthData()
            }
            #endif
        }
    )
}
