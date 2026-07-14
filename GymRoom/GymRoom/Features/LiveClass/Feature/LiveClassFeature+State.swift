//
//  LiveClassFeature+State.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 23/05/2026.
//

import ComposableArchitecture
import Foundation
import SharedModels

extension LiveClassFeature {

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

        /// Foreign key do `GymClassRecord` (template). Snapshot z momentu `startLiveClass`.
        /// Używany przy `gymClassClient.startSession(gymClassId:className:location:)` —
        /// trafia jako FK do nowego `ClassSessionRecord`. Domyślny `UUID()` tylko dla
        /// preview/test contexts (real flow zawsze passuje z parent ClassesListFeature).
        var gymClassId: UUID = UUID()

        /// Nazwa klasy — z `GymClass.name` (np. "Morning CrossFit"). Pokazana w header
        /// LiveClassView + wysyłana w QR payload jako `gymName` (peer widzi w `scannedQRPayload`).
        var className: String = "Gym Room"

        /// Sala — z `GymClass.location` (np. "Sala 1"). iPad-side context tylko —
        /// wyświetlany w header subtitle obok "LIVE". NIE wysyłany w QR.
        var location: String = ""

        /// Hard limit BLE z `GymClass.maxParticipants` (8/12/16, set w Class Creation
        /// z `bleCapacityClient.recommendedMaxConnections()`). Wyświetlany w header
        /// jako `current/max` ratio (np. "3/8 athletes") — trener widzi capacity od
        /// razu. Future: reject peer'ów gdy `athletes.count >= maxParticipants`.
        var maxParticipants: Int = 8

        /// Czy QR widget jest widoczny w corner overlay. Toggle dla trenera —
        /// można schować QR po dołączeniu wszystkich sportowców (less visual clutter).
        /// `true` = QR widoczny, `false` = mały toggle button żeby pokazać znowu.
        var isQRVisible: Bool = true

        /// Confirm dialog przed END Class. Trener musi potwierdzić — END affects wszystkich
        /// sportowców, accidental tap by zerwał klasę dla całej sali. `nil` = brak alertu,
        /// non-nil = alert visible.
        @Presents var alert: AlertState<Action.Alert>?

        /// End-of-class results table (IPAD-00095-A) — set once `confirmEnd`
        /// finished persisting and the ranking rows came back from the database.
        /// Presented as a fullScreenCover; `delegate(.classEnded)` fires only
        /// from its "Done" (the parent's handler tears the cover stack down).
        @Presents var results: ClassResultsFeature.State?

        // MARK: - Persistence (SQLiteData via gymClassClient)

        /// FK do current `ClassSessionRecord`. `nil` przed `startTapped` succeeds.
        /// Set'owany przez `sessionStarted` po async `gymClassClient.startSession(...)`.
        /// Używany przy `addAthlete` (classSessionId param) + `endSession` (confirmEnd).
        var activeSessionId: UUID?

        /// Mapping `deviceID` → `AthleteSessionRecord.id`. Set'owany przez `athleteAdded`,
        /// lookup przy `appendHRSamples` / `endAthlete` per peer. Cleared per peer w
        /// `peerDisconnected`, all-clear w `confirmEnd`.
        var athleteRecordIds: [UUID: UUID] = [:]

        /// Device IDs whose athlete-record creation is still in flight — the
        /// `athleteRecordIds` check alone races (it is only populated when the
        /// async `.athleteAdded` lands, so two quick samples both pass it and
        /// spawn two creates). Inserted before the create effect, removed on
        /// `.athleteAdded` / `.athleteCreationFailed`.
        var athleteCreationInFlight: Set<UUID> = []

        /// In-memory buffer surowych próbek per peer, keyed po `deviceID`. Append na każdą
        /// próbkę z BLE stream'a (`sampleReceived`). Flushed co 30s przez `persistenceTimer`
        /// effect lub na peer disconnect / class end. Po flush'u — clear (już persisted w BLOB).
        /// Trade-off: max 30s utraconych próbek na app crash. Acceptable dla MVP.
        var hrSamplesBuffer: [UUID: [HRSample]] = [:]
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

        /// Effort points computed on the ATHLETE'S device and delivered in each
        /// payload — the host only displays them (single source of truth: same
        /// number the athlete sees on their phone). `nil` = peer build without
        /// effort points → tile shows a dash.
        var effortPoints: Int? = nil

        /// `true` while the athlete's BLE strap is out of range (IOS-00100-C) —
        /// `bpm` is the frozen last-known value, not a live reading. The tile
        /// greys out instead of presenting it as live; the peer link itself is
        /// healthy (unlike `.reconnecting`), payloads keep arriving as keepalive.
        var isSensorStale: Bool = false

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
    /// - `.loading` — peer wykonał BLE handshake, ale **jeszcze nie wysłał pierwszego
    ///   `HRSamplePayload`**. Brak `maxHR` (real), brak BPM. Kafelek z spinner +
    ///   "Łączenie..." overlay. Po pierwszym sample → `.live` + CREATE w bazie z
    ///   real maxHR (lazy DB persistence, no fake placeholder).
    /// - `.live` — peer aktywnie broadcastuje HR (steady state)
    /// - `.reconnecting` — peer BLE-disconnect, czekamy 10s grace period; kafelek wyświetla
    ///   subtelny overlay (spinner + grayscale) ale **nie znika** — bo może wrócić
    /// - `.lost` nie istnieje jako persistent state — po grace timeout reducer od razu
    ///   usuwa tile z `state.athletes` (transient removal, brak migotania)
    enum TileState: Sendable, Equatable {
        case loading
        case live
        case reconnecting
    }
}
