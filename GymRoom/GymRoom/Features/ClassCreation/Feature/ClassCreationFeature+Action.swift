//
//  ClassCreationFeature+Action.swift
//  GymRoom
//
//  Created by Sebastian Ściuba on 13/06/2026.
//

import ComposableArchitecture
import Foundation

extension ClassCreationFeature {

    @CasePathable
    enum Action: ViewAction, BindableAction {

        // MARK: - Bindings

        /// Two-way bindings dla TextField'ów (`name`, `location`), Toggle (`hasSchedule`),
        /// DatePicker (`scheduledAt`), Stepper (`maxParticipants`). Pochodzi z `BindingReducer`.
        case binding(BindingAction<State>)


        // MARK: - View Actions

        case view(View)

        enum View {
            /// Pierwsze pojawienie się sheet'a — init `state.maxParticipants` +
            /// `maxParticipantsUpperBound` z `bleCapacityClient` (device-aware default).
            /// Idempotent: re-appear z non-zero `maxParticipants` nic nie zmienia.
            case viewDidAppear

            /// Tap "Save" w toolbar — validate, build `GymClass`, emit `.delegate(.classCreated)`.
            /// No-op gdy `isValid == false` (button disabled, ale guard dla bezpieczeństwa).
            case saveTapped

            /// Tap "Cancel" w toolbar — dismiss sheet bez delegate'u.
            case cancelTapped

            /// Tap na wiersz podpowiedzi adresu — ustawia `location` na wybrany
            /// adres i rozwiązuje współrzędne (`AddressSearchClient.resolve`).
            case addressSuggestionTapped(AddressSuggestion)
        }

        // MARK: - Internal (address search)

        /// Nowe podpowiedzi z `MKLocalSearchCompleter` (stream w `AddressSearchClient`).
        case addressSuggestionsUpdated([AddressSuggestion])

        /// Wybrana podpowiedź rozwiązana na współrzędne — zapis lat/lng do State.
        case addressResolved(ResolvedAddress)

        // MARK: - Delegate (parent — ClassesListFeature)

        /// Komunikaty do parent reducer'a. Parent reaguje: `.classCreated(gymClass)` →
        /// append do `state.classes` + dismiss sheet'a.
        case delegate(Delegate)

        enum Delegate: Equatable {
            /// User tap Save z poprawnym formularzem — parent dodaje klasę do listy.
            /// Wysłany `GymClass` ma już trimmed name/location + maxParticipants z state.
            case classCreated(GymClass)
        }
    }
}
