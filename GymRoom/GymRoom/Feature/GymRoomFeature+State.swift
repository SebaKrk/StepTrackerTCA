//
//  GymRoomFeature+State.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 23/05/2026.
//

import ComposableArchitecture
import Foundation
import SharedModels

extension GymRoomFeature {

    @ObservableState
    struct State {

        /// Czy klasa jest aktywna (advertising w sieci lokalnej, kafelki widoczne).
        var isLive: Bool = false

        /// Lista podłączonych athletów. Klucz = `deviceID` (per-install UUID peer'a).
        var athletes: IdentifiedArrayOf<AthleteTile> = []

        /// Stabilny identyfikator iPada (per-install). Generowany raz, persystowany.
        /// Wysyłany w QR payload jako `iPadID` — sanity check po stronie peer'a + debug.
        /// Future multi-room: peer może sprawdzić "scanned different iPad than last time".
        @Shared(.appStorage("gymRoomIPadID"))
        var iPadIDString: String = UUID().uuidString

        /// Decoded `iPadID` UUID. Force-unwrap safe — source `UUID().uuidString` zawsze
        /// daje format który `UUID(uuidString:)` parsuje sukces.
        var iPadID: UUID {
            UUID(uuidString: iPadIDString)!
        }

        /// Token sesji — rotowany przy każdym Start Class. Encoded w QR code.
        /// Peer wysyła go w `HRSamplePayload.sessionToken` (subtask C3), host validate'uje
        /// w `didReceiveWrite` i odrzuca peer'y z nieprawidłowym tokenem.
        /// `nil` w idle state (przed Start lub po End).
        var sessionToken: UUID?

        /// Display name sali — pokazywany w QR + peer side. PoC: hard-coded.
        /// Future: configurable (IPAD-0094 multi-room).
        var gymName: String = "Gym Room"

        /// Czy QR widget jest widoczny w corner overlay. Toggle dla trenera —
        /// można schować QR po dołączeniu wszystkich sportowców (less visual clutter).
        /// `true` = QR widoczny, `false` = mały toggle button żeby pokazać znowu.
        var isQRVisible: Bool = true

        /// Confirm dialog przed END Class. Trener musi potwierdzić — END affects wszystkich
        /// sportowców, accidental tap by zerwał klasę dla całej sali. `nil` = brak alertu,
        /// non-nil = alert visible.
        @Presents var alert: AlertState<Action.Alert>?
    }

    /// Pojedynczy kafelek athlety w grid.
    ///
    /// `id` = `deviceID` (= `HRSamplePayload.deviceID`). Stabilny per-install,
    /// niezależny od `CBPeripheral.identifier` (rotujący per BLE cycle) — pozwala
    /// rozpoznać że "ten sam peer wrócił" po disconnect/reconnect.
    /// `nick` jest tylko display name (może się powtarzać między peerami).
    struct AthleteTile: Identifiable, Sendable, Equatable {
        let id: UUID
        let nick: String
        var bpm: Int = 0
        var maxHR: Int = 190
        var activeEnergy: Double = 0
        var state: TileState = .live

        /// %HR obliczone z bpm / maxHR. Bezpieczne na maxHR = 0.
        var percentHR: Int {
            guard maxHR > 0 else { return 0 }
            return Int((Double(bpm) / Double(maxHR)) * 100)
        }

        /// Aktualna strefa HR — używana do gradient background + color tilea.
        var zone: HeartRateZone {
            let value = Double(percentHR) / 100
            return HeartRateZone.allCases.first { $0.percentageRange.contains(value) } ?? .resting
        }
    }

    /// Stan kafelka athlety w grace period architecture.
    ///
    /// - `.live` — peer aktywnie broadcastuje HR (default state)
    /// - `.reconnecting` — peer BLE-disconnect, czekamy 10s grace period; kafelek wyświetla
    ///   subtelny overlay (spinner + grayscale) ale **nie znika** — bo może wrócić
    /// - `.lost` nie istnieje jako persistent state — po grace timeout reducer od razu
    ///   usuwa tile z `state.athletes` (transient removal, brak migotania)
    enum TileState: Sendable, Equatable {
        case live
        case reconnecting
    }
}
