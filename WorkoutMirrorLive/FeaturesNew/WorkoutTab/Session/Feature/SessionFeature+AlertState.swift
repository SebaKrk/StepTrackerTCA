//
//  SessionFeature+AlertState.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 05/07/2026.
//

import ComposableArchitecture
import Foundation

extension SessionFeature {

    /// Domain actions of the connection-lost alert. `endAnyway` is the escape hatch:
    /// without it a physically unavailable Watch (left at home, dead battery) trapped
    /// the user on the session screen forever (user report 2026-07-09).
    enum ConnectionLostAlertAction: Equatable {

        /// Close the iPhone side of the session despite the dead mirroring link.
        /// The Watch (session owner) keeps its workout — the user ends it there
        /// whenever the device is back; `.workoutSaved` then arrives via the WC
        /// queue and is consumed by the app-level listener (IOS-00098).
        case endAnyway
    }
}

extension SessionFeature {

    /// Domain actions of the class-active alert — shown when the user taps End while
    /// still connected to a GymRoom class. `leaveAnyway` proceeds with the normal end;
    /// cancel keeps the workout (and the class connection) alive.
    enum ClassActiveAlertAction: Equatable {

        /// End the workout despite the class still running. Leaving before the trainer
        /// ends the class means this athlete disconnects and the iPad never delivers
        /// their recap (place/ranking) — hence the "data will be lost" warning.
        case leaveAnyway
    }
}

extension AlertState where Action == SessionFeature.ClassActiveAlertAction {

    /// Potwierdzenie zakończenia treningu, gdy uczestnik jest jeszcze połączony z salą
    /// (zajęcia trwają). Wyjście przed końcem zajęć = rozłączenie z iPada, więc recap
    /// (miejsce, ranking) nigdy nie dotrze — stąd ostrzeżenie o utracie danych.
    static var classActive: Self {
        AlertState {
            TextState(String(localized: "Class is still in progress"))
        } actions: {
            ButtonState(role: .cancel) {
                TextState(String(localized: "Stay"))
            }
            ButtonState(role: .destructive, action: .leaveAnyway) {
                TextState(String(localized: "Leave"))
            }
        } message: {
            TextState(String(localized: "Are you sure you want to end the workout? Class data will be lost."))
        }
    }
}

extension AlertState where Action == SessionFeature.ConnectionLostAlertAction {

    /// Instrukcja per dokumentacja Apple: gdy link mirroringu jest martwy (albo wysyłka
    /// `.workoutEnded` właśnie zawiodła), aplikacja ma poinstruować usera, by zakończył
    /// trening na urządzeniu będącym właścicielem sesji — na Watchu (IOS-00098-G/D).
    /// „Zakończ mimo to" — wyjście awaryjne gdy zegarek jest fizycznie niedostępny.
    static var connectionLost: Self {
        AlertState {
            TextState(String(localized: "No connection to Apple Watch"))
        } actions: {
            ButtonState(role: .cancel) {
                TextState(String(localized: "OK"))
            }
            ButtonState(role: .destructive, action: .endAnyway) {
                TextState(String(localized: "End anyway"))
            }
        } message: {
            TextState(String(localized: "The workout is still running on the watch. End it on Apple Watch by holding the Stop button."))
        }
    }
}
