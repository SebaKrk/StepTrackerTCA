//
//  PREntryEditorFeature.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 01/09/2026.
//

import ComposableArchitecture
import Foundation
import SharedModels

@Reducer
struct PREntryEditorFeature {

    // MARK: - Dependency

    @Dependency(\.prEntryClient) var prEntryClient
    @Dependency(\.personalDataClient) var personalDataClient
    @Dependency(\.uuid) var uuid
    @Dependency(\.date.now) var now
    @Dependency(\.dismiss) var dismiss

    // MARK: - Reducer

    var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .view(.saveTapped):
                guard let score = state.parsedScore else { return .none }
                // Captured up front so the entry is built EXACTLY ONCE inside the
                // effect — a second field-by-field copy is the bug class that
                // silently dropped scalingNote in PREntryClient (IOS-00128 review).
                let id = uuid()
                let createdAt = now
                let movement = state.movement
                let date = state.date
                let isRx = state.isRx
                let equipment = state.equipment
                let rpe = state.rpe
                let note = state.note
                let scalingNoteText = state.scalingNoteText
                let context = state.context
                return .run { [prEntryClient, personalDataClient] send in
                    // Body-weight snapshot must never block the save (US-01 acceptance).
                    let snapshot = (try? await personalDataClient.getWeightForDate(date)) ?? nil
                    let entry = PREntry(
                        id: id,
                        movementId: movement.id,
                        date: date,
                        createdAt: createdAt,
                        score: score,
                        isRx: movement.supportsRxScaled ? isRx : nil,
                        equipment: equipment,
                        rpe: rpe,
                        note: note.isEmpty ? nil : note,
                        // Scaling note travels only with a Scaled result — switching
                        // back to Rx must not smuggle a stale note into the entry.
                        scalingNote: movement.supportsRxScaled && !isRx && !scalingNoteText.isEmpty
                            ? scalingNoteText
                            : nil,
                        bodyWeightKg: snapshot?.value,
                        context: context
                    )
                    do {
                        try await prEntryClient.save(entry)
                    } catch {
                        // A failed save must be distinguishable from success:
                        // keep the sheet open and surface the alert.
                        reportIssue(error)
                        await send(.saveFailed)
                        return
                    }
                    await dismiss()
                }

            case .saveFailed:
                state.alert = AlertState {
                    TextState("Couldn't Save Result")
                } actions: {
                    ButtonState(role: .cancel) {
                        TextState("OK")
                    }
                } message: {
                    TextState("Your result was not saved. Please try again.")
                }
                return .none

            case .alert:
                return .none

            case .view(.cancelTapped):
                return .run { _ in await dismiss() }

            case let .view(.equipmentToggled(item)):
                if state.equipment.contains(item) {
                    state.equipment.remove(item)
                } else {
                    state.equipment.insert(item)
                }
                return .none

            case .binding:
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
    }
}
