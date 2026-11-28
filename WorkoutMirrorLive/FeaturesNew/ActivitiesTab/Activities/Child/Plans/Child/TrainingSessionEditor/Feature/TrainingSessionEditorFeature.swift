//
//  TrainingSessionEditorFeature.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 21/02/2026.
//

import ComposableArchitecture
import Foundation
import HealthHub
import SharedModels

@Reducer
struct TrainingSessionEditorFeature {

    // MARK: - Dependencies

    @Dependency(\.dismiss) var dismiss
    @Dependency(\.trainingNotesGeneratorClient) var notesClient

    // MARK: - Body

    var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce { state, action in
            switch action {

            case .binding:
                return .none

            case .view(.saveTapped):
                let session = TrainingSession(id: state.originalId, draft: state.draft)
                return .run { send in
                    await send(.delegate(.saved(session)))
                    await dismiss()
                }

            case .view(.deleteTapped):
                state.alert = .confirmDelete(title: state.draft.title)
                return .none

            case .alert(.presented(.deleteConfirmed)):
                let id = state.originalId
                return .run { send in
                    await send(.delegate(.deleted(id)))
                    await dismiss()
                }

            // MARK: - Warmup

            case .view(.warmUpToggled):
                if state.draft.warmUp == nil {
                    state.draft.warmUp = WarmUpSession(goal: .timeLimit, time: 10)
                } else if state.draft.warmUp?.description.isEmpty == false
                            || state.draft.warmUp?.block != nil
                            || state.isGeneratingWarmUpNotes {
                    state.alert = .removeWarmUp
                } else {
                    state.draft.warmUp = nil
                }
                return .none

            case .view(.warmUpTimeChanged(let time)):
                state.draft.warmUp?.time = time
                return .none

            case .view(.warmUpBlockEditTapped):
                state.destination = .warmUpBlockEditor(
                    WorkoutSessionEditorFeature.State(workout: state.draft.warmUp?.block)
                )
                return .none

            case .view(.warmUpBlockRemoveTapped):
                state.alert = .removeWarmUpBlock
                return .none

            case .view(.warmUpPartsSwapped):
                swapParts(warmUp: true, &state)
                return .none

            case let .view(.warmUpNotesChanged(notes)):
                state.draft.warmUp?.description = notes
                return .none

            case .view(.warmUpGenerateTapped):
                guard
                    state.draft.warmUp?.description.isEmpty == true,
                    !state.isGeneratingWarmUpNotes,
                    !state.draft.workouts.isEmpty
                else { return .none }
                guard state.isAIProcessingAllowed else {
                    state.alert = .confirmAIProcessing(allowed: .warmUpGenerationAllowed)
                    return .none
                }
                return generateWarmUp(&state)

            case .view(.coolDownGenerateTapped):
                guard
                    state.draft.coolDown?.description.isEmpty == true,
                    !state.isGeneratingCoolDownNotes,
                    !state.draft.workouts.isEmpty
                else { return .none }
                guard state.isAIProcessingAllowed else {
                    state.alert = .confirmAIProcessing(allowed: .coolDownGenerationAllowed)
                    return .none
                }
                return generateCoolDown(&state)

            // MARK: - Cooldown

            case .view(.coolDownToggled):
                if state.draft.coolDown == nil {
                    state.draft.coolDown = CoolDownSession(goal: .timeLimit, time: 10)
                } else if state.draft.coolDown?.description.isEmpty == false
                            || state.draft.coolDown?.block != nil
                            || state.isGeneratingCoolDownNotes {
                    state.alert = .removeCoolDown
                } else {
                    state.draft.coolDown = nil
                }
                return .none

            case .view(.coolDownTimeChanged(let time)):
                state.draft.coolDown?.time = time
                return .none

            case .view(.coolDownBlockEditTapped):
                state.destination = .coolDownBlockEditor(
                    WorkoutSessionEditorFeature.State(workout: state.draft.coolDown?.block)
                )
                return .none

            case .view(.coolDownBlockRemoveTapped):
                state.alert = .removeCoolDownBlock
                return .none

            case .view(.coolDownPartsSwapped):
                swapParts(warmUp: false, &state)
                return .none

            case let .view(.coolDownNotesChanged(notes)):
                state.draft.coolDown?.description = notes
                return .none

            case let .view(.sidePartDropped(dropped, target)):
                guard dropped.canSwap(with: target) else { return .none }
                swapParts(warmUp: target.isWarmUp, &state)
                return .none

            case let .view(.sidePartLifted(part)):
                // iOS 27 reports `.active` repeatedly during one drag — only the first lift may reset the target.
                guard state.draggedSidePart != part else { return .none }
                state.draggedSidePart = part
                state.sidePartDropTarget = nil
                return .none

            case .view(.sidePartDragEnded):
                state.draggedSidePart = nil
                state.sidePartDropTarget = nil
                return .none

            case let .view(.sidePartTargeted(part, isTargeted)):
                if isTargeted {
                    // Only the lifted part's partner lights up — the source itself, the other section and foreign drags never do.
                    guard state.draggedSidePart?.partner == part else { return .none }
                    state.sidePartDropTarget = part
                } else if state.sidePartDropTarget == part {
                    state.sidePartDropTarget = nil
                }
                return .none

            // MARK: - Alert

            case .alert(.presented(.warmUpRemoveConfirmed)):
                state.draft.warmUp = nil
                state.isGeneratingWarmUpNotes = false
                return .cancel(id: TrainingSessionEditorCancelID.warmUpGeneration)

            case .alert(.presented(.coolDownRemoveConfirmed)):
                state.draft.coolDown = nil
                state.isGeneratingCoolDownNotes = false
                return .cancel(id: TrainingSessionEditorCancelID.coolDownGeneration)

            case .alert(.presented(.warmUpGenerationAllowed)):
                state.$isAIProcessingAllowed.withLock { $0 = true }
                return generateWarmUp(&state)

            case .alert(.presented(.coolDownGenerationAllowed)):
                state.$isAIProcessingAllowed.withLock { $0 = true }
                return generateCoolDown(&state)

            case .alert(.presented(.warmUpBlockRemoveConfirmed)):
                state.draft.warmUp?.block = nil
                state.draft.warmUp?.order = nil
                return .none

            case .alert(.presented(.coolDownBlockRemoveConfirmed)):
                state.draft.coolDown?.block = nil
                state.draft.coolDown?.order = nil
                return .none

            case .alert:
                return .none

            // MARK: - Internal (AI generation results)

            case let .internal(.warmUpGenerationResult(.success(text))):
                state.isGeneratingWarmUpNotes = false
                state.draft.warmUp?.description = text
                return .none

            case let .internal(.warmUpGenerationResult(.failure(error))):
                state.isGeneratingWarmUpNotes = false
                // An open question (e.g. removing the section) outranks the failure notice.
                guard state.alert == nil else { return .none }
                state.alert = .generationFailed(ScanProxyError.userMessage(for: error))
                return .none

            case let .internal(.coolDownGenerationResult(.success(text))):
                state.isGeneratingCoolDownNotes = false
                state.draft.coolDown?.description = text
                return .none

            case let .internal(.coolDownGenerationResult(.failure(error))):
                state.isGeneratingCoolDownNotes = false
                // An open question (e.g. removing the section) outranks the failure notice.
                guard state.alert == nil else { return .none }
                state.alert = .generationFailed(ScanProxyError.userMessage(for: error))
                return .none

            // MARK: - Workouts

            case .view(.workoutAddTapped):
                state.destination = .workoutEditor(WorkoutSessionEditorFeature.State())
                return .none

            case .view(.workoutTapped(let workout)):
                state.destination = .workoutEditor(WorkoutSessionEditorFeature.State(workout: workout))
                return .none

            case .destination(.presented(.workoutEditor(.delegate(.saved(let workout))))):
                if let index = state.draft.workouts.firstIndex(where: { $0.id == workout.id }) {
                    state.draft.workouts[index] = workout
                } else {
                    state.draft.workouts.append(workout)
                }
                return .none

            case .destination(.presented(.workoutEditor(.delegate(.deleted(let id))))):
                state.draft.workouts.removeAll { $0.id == id }
                return .none

            // MARK: - Side blocks

            case .destination(.presented(.warmUpBlockEditor(.delegate(.saved(let block))))):
                state.draft.warmUp?.block = block
                return .none

            case .destination(.presented(.warmUpBlockEditor(.delegate(.deleted)))):
                state.draft.warmUp?.block = nil
                state.draft.warmUp?.order = nil
                return .none

            case .destination(.presented(.coolDownBlockEditor(.delegate(.saved(let block))))):
                state.draft.coolDown?.block = block
                return .none

            case .destination(.presented(.coolDownBlockEditor(.delegate(.deleted)))):
                state.draft.coolDown?.block = nil
                state.draft.coolDown?.order = nil
                return .none

            case .destination:
                return .none

            case .delegate:
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
        .ifLet(\.$destination, action: \.destination)
    }

    // MARK: - Helpers

    /// Asks the AI for the warm-up notes, written around the warm-up block; callers check the consent first.
    private func generateWarmUp(_ state: inout State) -> Effect<Action> {
        state.isGeneratingWarmUpNotes = true
        let warmUp = state.draft.warmUp
        let context = TrainingNotesContext(
            workouts: state.draft.workouts,
            durationMinutes: warmUp?.time,
            block: warmUp?.block,
            blockFirst: warmUp.map { $0.resolvedOrder == .blockFirst }
        )
        return .run { [notesClient] send in
            await send(.internal(.warmUpGenerationResult(
                Result { try await notesClient.generateWarmUp(context) }
            )))
        }
        .cancellable(id: TrainingSessionEditorCancelID.warmUpGeneration, cancelInFlight: true)
    }

    /// Asks the AI for the cool-down notes, written around the cool-down block; callers check the consent first.
    private func generateCoolDown(_ state: inout State) -> Effect<Action> {
        state.isGeneratingCoolDownNotes = true
        let coolDown = state.draft.coolDown
        let context = TrainingNotesContext(
            workouts: state.draft.workouts,
            durationMinutes: coolDown?.time,
            block: coolDown?.block,
            blockFirst: coolDown.map { $0.resolvedOrder == .blockFirst }
        )
        return .run { [notesClient] send in
            await send(.internal(.coolDownGenerationResult(
                Result { try await notesClient.generateCoolDown(context) }
            )))
        }
        .cancellable(id: TrainingSessionEditorCancelID.coolDownGeneration, cancelInFlight: true)
    }

    /// Flips which part of the warm-up or cool-down comes first and ends any drag state.
    private func swapParts(warmUp: Bool, _ state: inout State) {
        if warmUp {
            guard let current = state.draft.warmUp?.resolvedOrder else { return }
            state.draft.warmUp?.order = current == .blockFirst ? .notesFirst : .blockFirst
        } else {
            guard let current = state.draft.coolDown?.resolvedOrder else { return }
            state.draft.coolDown?.order = current == .blockFirst ? .notesFirst : .blockFirst
        }
        state.draggedSidePart = nil
        state.sidePartDropTarget = nil
    }
}
