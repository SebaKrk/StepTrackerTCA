//
//  ExercisePickerFeature+State.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 21/02/2026.
//

import ComposableArchitecture
import SharedModels

extension ExercisePickerFeature {

    @ObservableState
    struct State {

        /// Live search query entered by the user.
        var searchText: String = ""

        /// Optional category filter; `nil` means show all categories.
        var selectedCategory: MovementCategory? = nil

        // MARK: - Computed

        /// Exercises matching the current search query and category filter.
        var filteredExercises: [ExerciseType] {
            let all = ExerciseType.allCases.filter { $0 != .unknown }
            let byCategory = selectedCategory.map { cat in
                all.filter { $0.category == cat }
            } ?? all

            guard !searchText.isEmpty else { return byCategory }
            let query = searchText.lowercased()
            return byCategory.filter { type in
                type.displayName.lowercased().contains(query) ||
                type.aliases.contains { $0.lowercased().contains(query) }
            }
        }

        /// Exercises grouped by category, preserving the filtered set.
        var groupedExercises: [MovementCategory: [ExerciseType]] {
            Dictionary(grouping: filteredExercises, by: { $0.category })
        }

        /// Ordered list of categories present in `groupedExercises`.
        var visibleCategories: [MovementCategory] {
            groupedExercises.keys.sorted { $0.displayName < $1.displayName }
        }
    }
}
