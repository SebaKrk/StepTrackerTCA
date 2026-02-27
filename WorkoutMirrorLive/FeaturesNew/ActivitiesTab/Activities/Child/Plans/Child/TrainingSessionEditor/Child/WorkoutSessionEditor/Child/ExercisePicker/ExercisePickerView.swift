//
//  ExercisePickerView.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 21/02/2026.
//

import ComposableArchitecture
import SharedModels
import SwiftUI

@ViewAction(for: ExercisePickerFeature.self)
struct ExercisePickerView: View {

    // MARK: - Properties

    @Bindable var store: StoreOf<ExercisePickerFeature>

    // MARK: - Body

    var body: some View {
        List {
            ForEach(store.visibleCategories, id: \.self) { category in
                Section(category.displayName) {
                    ForEach(store.groupedExercises[category] ?? [], id: \.self) { exercise in
                        Button {
                            send(.exercisePicked(exercise))
                        } label: {
                            Text(exercise.displayName)
                                .foregroundStyle(.primary)
                        }
                    }
                }
            }
        }
        .searchable(text: $store.searchText, prompt: "Search exercises...")
        .navigationTitle("Choose Exercise")
        .navigationBarTitleDisplayMode(.inline)
    }
}
