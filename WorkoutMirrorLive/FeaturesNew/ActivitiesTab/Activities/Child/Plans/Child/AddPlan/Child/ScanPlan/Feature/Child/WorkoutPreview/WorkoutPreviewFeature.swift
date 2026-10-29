//
//  WorkoutPreviewFeature.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 12/02/2026.
//

import ComposableArchitecture
import SharedModels
import SwiftUI

/// Feature responsible for previewing a parsed workout before saving.
///
/// Displays the structured TrainingSession with all sections (warmup, workouts, cooldown)
/// and exercises. User can review the parsed data, edit it, or save it.
@Reducer
struct WorkoutPreviewFeature {

    // MARK: - State

    @ObservableState
    struct State {

        /// The color representing the training readiness level.
        @Shared(.inMemory(.readinessLevelColor))
        var color: Color = .gray

        /// The training session being previewed — updated after editing.
        var trainingSession: TrainingSession

        /// The plan exactly as the scan produced it; a block that differs from it was edited.
        var scannedSession: TrainingSession?

        /// Doubts, defaults and fixes from the board; close by "OK" or by editing their block.
        var boardFindings: IdentifiedArrayOf<ScanFinding> = []

        /// Rules on the plan; recomputed after every edit, confirmations carried over.
        var planFindings: IdentifiedArrayOf<ScanFinding> = []

        var isWarmupExpanded: Bool = true

        var isCooldownExpanded: Bool = true

        /// Everything the review card lists, board findings first.
        var findings: [ScanFinding] {
            Array(boardFindings) + Array(planFindings)
        }

        /// Saving waits until no finding is open.
        var canSave: Bool {
            !findings.contains(where: \.isOpen)
        }

        /// Open findings per block, for the badges in the plan.
        var openFindingCountsByBlock: [UUID: Int] {
            findings.filter(\.isOpen).reduce(into: [:]) { counts, finding in
                guard let blockId = finding.blockId else { return }
                counts[blockId, default: 0] += 1
            }
        }

        /// Movements with an open finding, for the icon next to their name.
        var flaggedExerciseIds: Set<UUID> {
            Set(findings.filter(\.isOpen).compactMap(\.exerciseId))
        }

        @Presents var destination: Destination.State?
    }

    // MARK: - Action

    @CasePathable
    enum Action: ViewAction {

        case view(View)
        case destination(PresentationAction<Destination.Action>)
        case delegate(Delegate)

        @CasePathable
        enum View {

            /// Called when user taps "Edit" — opens TrainingSessionEditorFeature.
            case editButtonTapped

            /// Called when user taps "Save" — persists and dismisses.
            case saveButtonTapped

            case warmupToggleTapped
            case cooldownToggleTapped

            /// User looked at the board and closed a doubt.
            case confirmFindingTapped(ScanFinding.ID)
        }

        enum Delegate {
            /// User saved the workout — passes session up so parent can persist.
            case saved(TrainingSession)
        }
    }

    // MARK: - Body

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {

            case .view(.editButtonTapped):
                state.destination = .editor(TrainingSessionEditorFeature.State(session: state.trainingSession))
                return .none

            case .view(.saveButtonTapped):
                guard state.canSave else { return .none }
                return .send(.delegate(.saved(state.trainingSession)))

            case let .view(.confirmFindingTapped(id)):
                state.boardFindings[id: id]?.isConfirmed = true
                state.planFindings[id: id]?.isConfirmed = true
                return .none

            case .view(.warmupToggleTapped):
                state.isWarmupExpanded.toggle()
                return .none

            case .view(.cooldownToggleTapped):
                state.isCooldownExpanded.toggle()
                return .none

            case .destination(.presented(.editor(.delegate(.saved(let session))))):
                state.trainingSession = session
                // Rules re-run on the edited plan; a doubt about a block the user touched is settled.
                let previous = state.planFindings
                state.planFindings = IdentifiedArray(
                    uniqueElements: ScanReviewValidator.planFindings(session).map { finding in
                        var finding = finding
                        finding.isConfirmed = previous.contains { $0.isSameIssue(as: finding) && $0.isConfirmed }
                        return finding
                    }
                )
                let scannedBlocks = Dictionary(uniqueKeysWithValues: (state.scannedSession?.workouts ?? []).map { ($0.id, $0) })
                state.boardFindings.removeAll { finding in
                    guard let blockId = finding.blockId, let edited = session.workouts.first(where: { $0.id == blockId }) else {
                        return false
                    }
                    return scannedBlocks[blockId] != edited
                }
                return .none

            case .destination:
                return .none

            case .delegate:
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }

}
