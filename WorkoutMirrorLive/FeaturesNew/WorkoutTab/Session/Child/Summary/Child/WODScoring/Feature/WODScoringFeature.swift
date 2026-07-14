//
//  WODScoringFeature.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 27/06/2026.
//

import ComposableArchitecture
import Foundation
import SharedModels

/// Child feature dla pojedynczego WOD'a w SummaryFeature. Zarządza:
/// - `result: WorkoutSessionResult` (score, note, exercises[])
/// - UI toggle flags (showResults, showNotes, exercisesEdited)
///
/// **Po co child feature**: parent `SummaryFeature.State` miało 4 paralelne arrays
/// (`resultInputs`, `showResults`, `showNotes`, `exercisesEdited`) keyed by index'em.
/// To classic anti-pattern: drift gdy długość się zmienia + cascading re-renders przy
/// każdej zmianie pojedynczego pola. `IdentifiedArrayOf<WODScoringFeature.State>` rozwiązuje
/// oba problemy: stable ID per WOD + element-level observability.
///
/// **Delegate `requestEditExercises`**: child NIE prezentuje SetInputSheet bezpośrednio —
/// emit'uje request do parent'a (SummaryFeature) który posiada `@Presents var setInput`
/// i renderuje sheet w głównym SummaryView. Powód: sheet musi być na poziomie SummaryView,
/// nie per-WOD card (multiple sheets w ForEach = SwiftUI conflict).
@Reducer
struct WODScoringFeature {

    // MARK: - State

    @ObservableState
    struct State: Equatable, Identifiable {

        /// Stable index z `trainingSession.workouts[index]`. Source of truth dla `id`.
        /// Template'y są immutable po stworzeniu workout'u, więc indeks jest stabilny.
        let wodIndex: Int

        /// Wynik tego WOD'a — score, note, lista exercise inputs.
        var result: WorkoutSessionResult

        /// UI: czy sekcja "Wynik" jest rozwinięta (TextField na scoreText widoczny).
        var showResults: Bool = false

        /// UI: czy sekcja "Notatki" jest rozwinięta (TextEditor widoczny).
        var showNotes: Bool = false

        /// UI: czy user otworzył SetInputSheet dla tego WOD'a (badge "Edytowano").
        /// Parent (SummaryFeature) ustawia po `setInput(.dismiss)`.
        var exercisesEdited: Bool = false

        var id: Int { wodIndex }

        init(
            wodIndex: Int,
            result: WorkoutSessionResult,
            showResults: Bool = false,
            showNotes: Bool = false,
            exercisesEdited: Bool = false
        ) {
            self.wodIndex = wodIndex
            self.result = result
            self.showResults = showResults
            self.showNotes = showNotes
            self.exercisesEdited = exercisesEdited
        }
    }

    // MARK: - Action

    @CasePathable
    enum Action: ViewAction, BindableAction {

        /// Binding dla TextField'ów (scoreText, note) — synchronous mutation przez `@Bindable`.
        case binding(BindingAction<State>)

        case view(View)

        case delegate(Delegate)

        @CasePathable
        enum View {

            /// Toggle rozwinięcie sekcji "Wynik". Collapse → czyści score + note (defensive reset).
            case toggleResultsExpand

            /// Toggle rozwinięcie sekcji "Notatki". Collapse → czyści note.
            case toggleNotesExpand

            /// User chce edytować ćwiczenia w SetInputSheet → emit delegate do parent'a.
            case editExercisesTapped
        }

        @CasePathable
        enum Delegate: Equatable {

            /// Request do SummaryFeature: otwórz SetInputSheet dla tego WOD'a.
            /// Parent buduje `SetInputFeature.State` z `wodIndex` + decyduje co dalej.
            case requestEditExercises(wodIndex: Int)
        }
    }

    // MARK: - Reducer

    var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce { state, action in
            switch action {

            case .binding:
                return .none

            case .view(.toggleResultsExpand):
                state.showResults.toggle()
                if !state.showResults {
                    // Collapse Wynik → reset (defensive, jak w SummaryFeature.swift:357-362).
                    state.showNotes = false
                    state.result.scoreResult = .completed
                    state.result.note = ""
                }
                return .none

            case .view(.toggleNotesExpand):
                state.showNotes.toggle()
                if !state.showNotes {
                    state.result.note = ""
                }
                return .none

            case .view(.editExercisesTapped):
                return .send(.delegate(.requestEditExercises(wodIndex: state.wodIndex)))

            case .delegate:
                return .none
            }
        }
    }
}
