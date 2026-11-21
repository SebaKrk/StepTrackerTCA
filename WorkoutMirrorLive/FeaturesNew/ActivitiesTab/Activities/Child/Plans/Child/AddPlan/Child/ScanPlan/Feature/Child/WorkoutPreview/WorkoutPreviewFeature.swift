//
//  WorkoutPreviewFeature.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 12/02/2026.
//

import ComposableArchitecture
import HealthHub
import SharedModels
import SwiftUI

/// Feature responsible for previewing a parsed workout before saving.
///
/// Displays the structured TrainingSession with all sections (warmup, workouts, cooldown)
/// and exercises. User can review the parsed data, edit it, or save it.
@Reducer
struct WorkoutPreviewFeature {

    // MARK: - Dependencies

    @Dependency(\.trainingNotesGeneratorClient) var notesClient

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

        /// Warm-up card expanded.
        var isWarmupExpanded: Bool = true

        /// Cool-down card expanded.
        var isCooldownExpanded: Bool = true

        /// Warm-up and cool-down are being generated for the sections the board did not have.
        var isGeneratingNotes = false

        /// Whether the user agreed to send plans to the AI service; asked once, revocable in settings.
        @Shared(.appStorage(.aiProcessingConsent))
        var isAIProcessingAllowed = false

        /// Everything the review card lists, board findings first.
        var findings: [ScanFinding] {
            Array(boardFindings) + Array(planFindings)
        }

        /// Saving waits until no finding is open and no generation is in flight — otherwise the plan
        /// would be stored without the sections the user just asked for.
        var canSave: Bool {
            !findings.contains(where: \.isOpen) && !isGeneratingNotes
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

        /// The board had no warm-up, no cool-down, or neither — the offer to generate them shows.
        var canGenerateNotes: Bool {
            !trainingSession.workouts.isEmpty
                && (trainingSession.warmUp == nil || trainingSession.coolDown == nil)
        }

        /// Generation failure, or the consent asked before the first generation.
        @Presents var alert: AlertState<Action.Alert>?

        @Presents var destination: Destination.State?
    }

    // MARK: - Action

    @CasePathable
    enum Action: ViewAction {

        // MARK: - View Actions

        case view(View)

        // MARK: - Internal Actions

        /// Internal — generated texts for the sections the board lacked; `nil` where the plan already had one.
        case notesGenerated(TrainingNotes)

        /// Internal — generation failed; carries the message to show.
        case notesGenerationFailed(String)

        // MARK: - Alert

        /// Generation failure alert.
        case alert(PresentationAction<Alert>)

        // MARK: - Destination

        case destination(PresentationAction<Destination.Action>)

        // MARK: - Delegate

        case delegate(Delegate)

        // MARK: - View

        @CasePathable
        enum View {

            /// Called when user taps "Edit" — opens TrainingSessionEditorFeature.
            case editButtonTapped

            /// Called when user taps "Save" — persists and dismisses.
            case saveButtonTapped

            /// Called when the user asks for a warm-up and cool-down the board did not have.
            case generateNotesTapped

            /// Toggles the warm-up card.
            case warmupToggleTapped

            /// Toggles the cool-down card.
            case cooldownToggleTapped

            /// User looked at the board and closed a doubt.
            case confirmFindingTapped(ScanFinding.ID)
        }

        // MARK: - Alert Actions

        enum Alert: Equatable {

            /// Called when the user agrees to send plans to the AI service.
            case aiProcessingAllowed
        }

        // MARK: - Delegate Actions

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
                guard !state.isGeneratingNotes else { return .none }
                state.destination = .editor(TrainingSessionEditorFeature.State(session: state.trainingSession))
                return .none

            case .view(.saveButtonTapped):
                guard state.canSave else { return .none }
                return .send(.delegate(.saved(state.trainingSession)))

            // Only the missing sections are generated, with the editor's default length.
            case .view(.generateNotesTapped):
                guard state.canGenerateNotes, !state.isGeneratingNotes else { return .none }
                guard state.isAIProcessingAllowed else {
                    state.alert = .confirmAIProcessing
                    return .none
                }
                return generateNotes(&state)

            // MARK: - Alert

            case .alert(.presented(.aiProcessingAllowed)):
                state.$isAIProcessingAllowed.withLock { $0 = true }
                return generateNotes(&state)

            // MARK: - Internal

            case let .notesGenerated(notes):
                state.isGeneratingNotes = false
                state.trainingSession = Self.plan(
                    state.trainingSession,
                    warmUp: notes.warmUp.map {
                        WarmUpSession(goal: .timeLimit, time: notes.warmUpMinutes ?? Self.generatedNotesMinutes, description: $0)
                    },
                    coolDown: notes.coolDown.map {
                        CoolDownSession(goal: .timeLimit, time: notes.coolDownMinutes ?? Self.generatedNotesMinutes, description: $0)
                    }
                )
                return .none

            case let .notesGenerationFailed(message):
                state.isGeneratingNotes = false
                state.alert = .notesGenerationFailed(message)
                return .none

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

            case .alert, .destination, .delegate:
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
        .ifLet(\.$destination, action: \.destination)
    }

    // MARK: - Helpers

    /// Asks the AI service for the sections the board lacked; callers check the consent first.
    private func generateNotes(_ state: inout State) -> Effect<Action> {
        state.isGeneratingNotes = true
        // No length is sent: nobody picked one here, so the model proposes it.
        let context = TrainingNotesContext(
            workouts: state.trainingSession.workouts,
            durationMinutes: nil
        )
        let needsWarmUp = state.trainingSession.warmUp == nil
        let needsCoolDown = state.trainingSession.coolDown == nil
        return .run { [notesClient] send in
            await send(.notesGenerated(try await notesClient.generateMissing(context, needsWarmUp, needsCoolDown)))
        } catch: { error, send in
            await send(.notesGenerationFailed(ScanProxyError.userMessage(for: error)))
        }
        .cancellable(id: WorkoutPreviewCancelID.notesGeneration, cancelInFlight: true)
    }

    /// Default length of a generated warm-up or cool-down, same as a section added in the editor.
    private static let generatedNotesMinutes = 10

    // The scanned blocks stay untouched; only the missing sections are filled in.
    private static func plan(_ plan: TrainingSession, warmUp: WarmUpSession?, coolDown: CoolDownSession?) -> TrainingSession {
        TrainingSession(
            id: plan.id,
            date: plan.date,
            title: plan.title,
            activity: plan.activity,
            location: plan.location,
            warmUp: plan.warmUp ?? warmUp,
            workouts: plan.workouts,
            coolDown: plan.coolDown ?? coolDown,
            teamPlanId: plan.teamPlanId
        )
    }
}
