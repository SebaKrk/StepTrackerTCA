//
//  ClassCreationFeature+State.swift
//  GymRoom
//
//  Created by Sebastian Ściuba on 13/06/2026.
//

import ComposableArchitecture
import Foundation

extension ClassCreationFeature {

    @ObservableState
    struct State: Equatable {

        /// Nazwa klasy treningowej (np. "Morning CrossFit"). Mandatory — pusta po trim
        /// blokuje Save button (`isValid == false`).
        var name: String = ""

        /// Sala / lokalizacja (np. "Sala 1"). Mandatory — pusta po trim blokuje Save.
        /// Wyświetlana jako subtitle w row liście klas + w header LiveClassView.
        var location: String = ""

        /// Toggle "Set scheduled time" — gdy `true`, klasa dostaje `scheduledAt`,
        /// gdy `false` — `scheduledAt = nil` (sekcja "Bez daty" w liście).
        var hasSchedule: Bool = false

        /// Data + godzina planowanego startu. Ignorowane gdy `hasSchedule == false`.
        var scheduledAt: Date = .now

        /// Aktualny wybór trenera w Stepper'ze (1...`maxParticipantsUpperBound`).
        /// Sentinel `0` = uninit. `viewDidAppear` ustawia na `deviceCapacity` (hard
        /// limit hardware'u — user widzi recommended default i może zmniejszyć lub
        /// próbować zwiększyć, ale przekroczenie `deviceCapacity` blokuje Save.
        var maxParticipants: Int = 0

        /// Hardware BLE limit dla tego device'a — z `bleCapacityClient.recommendedMaxConnections()`.
        /// iPad Pro M-series = 16, iPad Air 5 / Pro A12X = 12, pozostałe iPady = 8.
        /// Sentinel `0` = uninit. Set raz w `viewDidAppear`.
        var deviceCapacity: Int = 0

        /// Górny range Stepper'a — uniwersalna stała `16` (Apple practical cap niezależny
        /// od device'a). User może klikać ponad `deviceCapacity` — dostanie inline error
        /// + Save disabled, ale fizycznie nie wyklika powyżej 16.
        var maxParticipantsUpperBound: Int = GymClassCapacity.upperBound

        /// `true` gdy user wybrał więcej niż device wytrzyma — wyzwala czerwony footer
        /// + blokuje Save (`isValid` zawiera `!exceedsDeviceLimit`).
        var exceedsDeviceLimit: Bool {
            maxParticipants > deviceCapacity
        }

        /// Czy Save button jest aktywny. Trzy warunki: trimmed name non-empty +
        /// trimmed location non-empty + capacity w granicach hardware'u.
        var isValid: Bool {
            !name.trimmingCharacters(in: .whitespaces).isEmpty &&
            !location.trimmingCharacters(in: .whitespaces).isEmpty &&
            !exceedsDeviceLimit
        }
    }
}
