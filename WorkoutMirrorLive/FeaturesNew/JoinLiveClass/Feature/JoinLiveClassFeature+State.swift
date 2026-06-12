//
//  JoinLiveClassFeature+State.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 23/05/2026.
//

import ComposableArchitecture
import Foundation
import SharedModels

extension JoinLiveClassFeature {

    @ObservableState
    struct State {

        /// Nick athlety. Persystowany w AppStorage, default = "Athlete-XXX".
        /// Klucz w camelCase (KVO nie pozwala na kropki) — TODO: przenieść do `AppStorageKeys`.
        @Shared(.appStorage("joinLiveClassNick"))
        var nick: String = "Athlete-\(Int.random(in: 100...999))"

        /// Stabilny identyfikator urządzenia peer'a (per-install na iPhone).
        /// Generowany raz przy pierwszym uruchomieniu, persystowany w AppStorage.
        /// Wysyłany w każdym `HRSamplePayload` jako primary key — host indexuje
        /// po nim `connectedCentrals`, dzięki czemu reconnect detection działa
        /// niezależnie od `CBPeripheral.identifier` (Apple rotuje per BLE cycle).
        @Shared(.appStorage("joinLiveClassDeviceID"))
        var deviceIDString: String = UUID().uuidString

        /// Decoded `deviceID` jako UUID. Force-unwrap bezpieczny: default value
        /// (`UUID().uuidString`) zawsze daje format który `UUID(uuidString:)` parsuje.
        var deviceID: UUID {
            UUID(uuidString: deviceIDString)!
        }

        /// Aktualna faza UI.
        var phase: Phase = .idle

        /// Maksymalny HR athlety, propagowany z parent `SessionFeature` przy creation
        /// w `.joinLiveClassToolbarButtonTapped` i aktualizowany przy `.setMaxHR`.
        /// Default 190 jako fallback gdy parent nie zdążył jeszcze obliczyć
        /// (race przy szybkim joinLiveClass tap przed `makeCalculationForSession`).
        var maxHeartRate: Int = 190

        /// Zdekodowany QR payload po scan'ie. `nil` = jeszcze nie scanned.
        /// Ephemeral — NIE persistujemy. Reset na `.leaveTapped` wymusza ponowny scan
        /// przy następnym Join. `sessionToken` z payload'u wysyłany w `HRSamplePayload`.
        var scannedQRPayload: QRSessionPayload?

        /// Czy QR scanner (fullScreenCover) jest aktualnie widoczny.
        /// Set przez `.joinTapped`, unset przez `.qrScanned` (po successful scan)
        /// lub `.scannerDismissed` (gdy user swipe-down bez scanowania).
        var isShowingScanner: Bool = false
    }

    enum Phase: Equatable, Sendable {
        case idle
        case searching
        case connected
    }
}
