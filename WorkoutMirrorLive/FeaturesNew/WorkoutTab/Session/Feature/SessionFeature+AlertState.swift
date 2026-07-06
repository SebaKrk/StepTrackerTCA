//
//  SessionFeature+AlertState.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 05/07/2026.
//

import ComposableArchitecture
import Foundation

extension AlertState where Action == Never {

    /// Instrukcja per dokumentacja Apple: gdy link mirroringu jest martwy (albo wysyłka
    /// `.workoutEnded` właśnie zawiodła), aplikacja ma poinstruować usera, by zakończył
    /// trening na urządzeniu będącym właścicielem sesji — na Watchu (IOS-00098-G/D).
    static var connectionLost: Self {
        AlertState {
            TextState(String(localized: "Brak połączenia z Apple Watch"))
        } actions: {
            ButtonState(role: .cancel) {
                TextState(String(localized: "OK"))
            }
        } message: {
            TextState(String(localized: "Trening nadal trwa na zegarku. Zakończ go na Apple Watch, przytrzymując przycisk Stop."))
        }
    }
}
