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

        /// `nil` = create mode (nowy template z fresh UUID przy Save). Non-nil = edit
        /// mode (upsert do istniejącego rzędu — SQLite ON CONFLICT REPLACE po id).
        /// Set przez custom `init(editing: GymClass)` używany w `ClassDetailFeature.editTapped`.
        var editingId: UUID?

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

        /// Custom init dla edit mode — prefill wszystkie pola z istniejącego template'a.
        /// `editingId` set'owany na `gymClass.id` → przy Save upsert nadpisze istniejący
        /// rząd (zamiast tworzyć nowy z fresh UUID).
        init(editing gymClass: GymClass) {
            self.editingId = gymClass.id
            self.name = gymClass.name
            self.location = gymClass.location
            self.hasSchedule = gymClass.scheduledAt != nil
            self.scheduledAt = gymClass.scheduledAt ?? .now
            self.maxParticipants = gymClass.maxParticipants
            self.deviceCapacity = gymClass.maxParticipants
            // maxParticipantsUpperBound zostaje default; viewDidAppear i tak nie nadpisze
            // bo `maxParticipants != 0` (sentinel check).
        }

        /// Default init dla create mode — wszystkie pola domyślne (memberwise synthesis).
        init() {}
    }
}
