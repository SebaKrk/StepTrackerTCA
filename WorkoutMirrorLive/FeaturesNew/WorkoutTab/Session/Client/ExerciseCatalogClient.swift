//
//  ExerciseCatalogClient.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 24/04/2026.
//

import ComposableArchitecture
import Foundation
import SharedModels

// MARK: - Client

struct ExerciseCatalogClient: Sendable {
    var match: @Sendable (String) -> ExerciseType?
    var categoryFor: @Sendable (ExerciseType) -> MovementCategory
}

// MARK: - DependencyValues

extension DependencyValues {
    var exerciseCatalogClient: ExerciseCatalogClient {
        get { self[ExerciseCatalogClientKey.self] }
        set { self[ExerciseCatalogClientKey.self] = newValue }
    }
}

// MARK: - DependencyKey

private enum ExerciseCatalogClientKey: DependencyKey {

    static let liveValue = ExerciseCatalogClient(
        match: { name in
            let normalized = name
                .trimmingCharacters(in: .whitespaces)
                .lowercased()

            // 1. Exact match by displayName
            if let type = ExerciseType.allCases.first(where: {
                $0.displayName.lowercased() == normalized
            }) {
                return type
            }

            // 2. Alias match
            if let type = ExerciseType.allCases.first(where: {
                $0.aliases.contains(where: { $0.lowercased() == normalized })
            }) {
                return type
            }

            // 3. Prefix match (singular/plural)
            if let type = ExerciseType.allCases.first(where: {
                let display = $0.displayName.lowercased()
                return display.hasPrefix(normalized) || normalized.hasPrefix(display)
            }) {
                return type
            }

            return nil
        },
        categoryFor: { type in
            type.category
        }
    )

    static var testValue: ExerciseCatalogClient {
        ExerciseCatalogClient(
            match: unimplemented("ExerciseCatalogClient.match"),
            categoryFor: unimplemented("ExerciseCatalogClient.categoryFor")
        )
    }
}
