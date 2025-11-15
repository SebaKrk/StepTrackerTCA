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
    var isAvailable: @Sendable () async -> Bool = { false }
}

extension DependencyValues {
    var dataAnalyzerClient: DataAnalyzerClient {
        get { self[DataAnalyzerClient.self] }
        set { self[DataAnalyzerClient.self] = newValue }
    }
}

// MARK: - Live Implementation

extension DataAnalyzerClient: DependencyKey {
    static let liveValue = DataAnalyzerClient(
        isAvailable: {
            #if canImport(FoundationModels)
                return DataAnalyzer.shared.available
            #else
            return false
            #endif
        }
    )
}
