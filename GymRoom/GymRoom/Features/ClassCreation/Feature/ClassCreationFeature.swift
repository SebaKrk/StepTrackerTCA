//
//  ClassCreationFeature.swift
//  GymRoom
//
//  Created by Sebastian Ściuba on 13/06/2026.
//

import ComposableArchitecture
import Foundation
import PeerMirror

/// Reducer dla sheet'a do tworzenia nowej klasy w grafiku (Classes tab → toolbar `+`).
///
/// **Pola formularza** (definiowane w `+State.swift`):
/// - `name` — mandatory ("Morning CrossFit")
/// - `location` — mandatory ("Sala 1")
/// - `scheduledAt` — optional (Toggle + DatePicker)
/// - `maxParticipants` — BLE concurrent peer limit (device-aware default)
///
/// **Flow**: Save → validate → build `GymClass` → `.delegate(.classCreated)` →
/// parent (`ClassesListFeature`) appenduje do listy + dismiss.
///
/// **Capacity defaults**: z `bleCapacityClient` w `viewDidAppear` (per-device
/// recommendation z `hw.machine`). Patrz: `PeerMirror.BLECapacityClient`.
@Reducer
struct ClassCreationFeature {

    @Dependency(\.dismiss) var dismiss
    @Dependency(\.bleCapacityClient) var bleCapacityClient

    var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce<State, Action> { state, action in
            switch action {
            case .view(.viewDidAppear):
                // Init device-aware capacity defaults. Sentinel 0 == uninit; po pierwszym
                // appear non-zero, re-appear nic nie zmienia (idempotent).
                if state.maxParticipants == 0 {
                    state.deviceCapacity = bleCapacityClient.recommendedMaxConnections()
                    state.maxParticipants = state.deviceCapacity
                    state.maxParticipantsUpperBound = bleCapacityClient.upperBound()
                }
                return .none

            case .view(.saveTapped):
                guard state.isValid else { return .none }
                // Zachowaj `id` w edit mode (upsert → update istniejący rząd).
                // W create mode fresh UUID → nowy row. SQLiteData `upsert` rozróżnia
                // per PRIMARY KEY ON CONFLICT REPLACE.
                let id = state.editingId ?? UUID()
                let savedClass = GymClass(
                    id: id,
                    name: state.name.trimmingCharacters(in: .whitespaces),
                    location: state.location.trimmingCharacters(in: .whitespaces),
                    scheduledAt: state.hasSchedule ? state.scheduledAt : nil,
                    maxParticipants: state.maxParticipants
                )
                return .send(.delegate(.classCreated(savedClass)))

            case .view(.cancelTapped):
                return .run { _ in await self.dismiss() }

            case .binding, .delegate:
                return .none
            }
        }
    }
}
