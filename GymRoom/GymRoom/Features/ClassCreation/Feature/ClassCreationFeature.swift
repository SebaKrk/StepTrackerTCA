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
    @Dependency(\.addressSearchClient) var addressSearchClient
    @Dependency(\.continuousClock) var clock

    /// `nonisolated` — required under the project's `defaultIsolation(MainActor.self)`
    /// so the CancelID satisfies `Sendable` for effect cancellation.
    nonisolated enum CancelID: Hashable, Sendable {
        case addressSuggestions
    }

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
                    maxParticipants: state.maxParticipants,
                    latitude: state.selectedLatitude,
                    longitude: state.selectedLongitude,
                    // Recurrence needs a base date — a class "without date" can't repeat.
                    isRecurring: state.hasSchedule && state.isRecurring
                )
                return .send(.delegate(.classCreated(savedClass)))

            case .view(.cancelTapped):
                return .run { _ in await self.dismiss() }

            case let .view(.addressSuggestionTapped(suggestion)):
                // Commit the picked address immediately; resolve coordinates in the
                // background. Setting `location` here (not via binding) does NOT
                // re-trigger the suggestions stream, so the dropdown stays closed.
                state.location = suggestion.displayAddress
                state.locationSuggestions = []
                return .merge(
                    .cancel(id: CancelID.addressSuggestions),
                    .run { send in
                        guard let resolved = try? await addressSearchClient.resolve(suggestion) else { return }
                        await send(.addressResolved(resolved))
                    }
                )

            case let .addressSuggestionsUpdated(suggestions):
                state.locationSuggestions = suggestions
                return .none

            case let .addressResolved(resolved):
                state.selectedLatitude = resolved.latitude
                state.selectedLongitude = resolved.longitude
                return .none

            case .binding(\.location):
                // Manual edit invalidates any previously resolved coordinates.
                state.selectedLatitude = nil
                state.selectedLongitude = nil
                let query = state.location
                guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
                    state.locationSuggestions = []
                    return .cancel(id: CancelID.addressSuggestions)
                }
                // Debounce via cancelInFlight: each keystroke cancels the pending
                // sleep before the completer subscription starts.
                return .run { send in
                    try? await clock.sleep(for: .milliseconds(250))
                    for await suggestions in addressSearchClient.suggestions(query) {
                        await send(.addressSuggestionsUpdated(suggestions))
                    }
                }
                .cancellable(id: CancelID.addressSuggestions, cancelInFlight: true)

            case .binding, .delegate:
                return .none
            }
        }
    }
}
