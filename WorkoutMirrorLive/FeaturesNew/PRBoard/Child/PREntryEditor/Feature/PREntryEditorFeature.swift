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
                guard let kilograms = state.parsedWeight else { return .none }
                let entry = PREntry(
                    id: uuid(),
                    movementId: state.movement.id,
                    date: state.date,
                    createdAt: now,
                    score: .weight(kilograms: kilograms),
                    isRx: state.movement.supportsRxScaled ? state.isRx : nil,
                    equipment: state.equipment,
                    rpe: state.rpe,
                    note: state.note.isEmpty ? nil : state.note,
                    bodyWeightKg: nil,
                    context: state.context
                )
                return .run { [prEntryClient, personalDataClient] send in
                    // Body-weight snapshot must never block the save (US-01 acceptance).
                    let snapshot = (try? await personalDataClient.getWeightForDate(entry.date)) ?? nil
                    let enriched = PREntry(
                        id: entry.id,
                        movementId: entry.movementId,
                        date: entry.date,
                        createdAt: entry.createdAt,
                        score: entry.score,
                        isRx: entry.isRx,
                        equipment: entry.equipment,
                        rpe: entry.rpe,
                        note: entry.note,
                        bodyWeightKg: snapshot?.value,
                        context: entry.context
                    )
                    do {
                        try await prEntryClient.save(enriched)
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
