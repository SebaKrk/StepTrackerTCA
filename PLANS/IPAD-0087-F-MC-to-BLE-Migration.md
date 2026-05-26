# IPAD-0087-F · Migracja MultipeerConnectivity → Bluetooth LE Direct

**Autor**: Sebastian Ściuba
**Data**: 2026-05-25
**Status**: Plan / Active (subtask F of IPAD-0087 PoC)
**Branch**: `dev/IPAD-00087/IPAD-00087` (current — kontynuacja istniejącej pracy, brak nowego brancha)
**Position w roadmap**: subtask F po A-E (A: iPad scaffold, B: PeerMirrorClient/Service MC, C: GymRoomFeature, D: JoinLiveClassFeature, E: UI polish + i18n)
**Note**: oryginalny `IPAD-0094` z `IPAD-0087-GymRoom-PoC.md` zakładał "MC → Bonjour + WebSocket server" — kierunek zmieniony na BLE Direct bo lepiej spełnia wymóg "user nie na Wi-Fi boxu" + zachowuje zero-infrastructure model

---

## 🎯 Cel

Wymienić transport komunikacji iPhone↔iPad z **MultipeerConnectivity** (wymaga tej samej Wi-Fi, hard limit 8 total devices) na **Bluetooth Low Energy direct** (zero Wi-Fi, naturalna proximity przez radio range, BLE 5.3 chipsety w modern iPhone/iPad obsługują znacznie więcej niż 8 connections — finalna liczba zweryfikowana empirycznie w Subtaska F.E).

To zachowuje peer-to-peer model (**zero infrastruktury**, zero serwera, zero internetu) i rozwiązuje dwa główne pain pointy z PoC:

1. User **nie musi** podpinać się do Wi-Fi boxu (działa na 5G, dowolnej Wi-Fi, lub bez Wi-Fi)
2. Naturalna proximity check — radio range BLE (~10-30m) automatycznie wymusza "user musi być w sali"

---

## ✅ Success criterion (Definition of Done)

- [ ] iPhone bez podpięcia do Wi-Fi boxu (na 5G lub Wi-Fi wyłączona) wykrywa iPada i ustanawia połączenie BLE w <3s
- [ ] HR samples lecą z iPhone'a do iPada przez BLE write/notify z latency <500ms
- [ ] iPad utrzymuje **co najmniej 8 jednoczesnych** iPhone connections (target: 15+, finalna liczba po smoke teście)
- [ ] User wychodzący z sali (~30m+ od iPada) automatycznie disconnect przez RSSI drop → tile na iPadzie znika
- [ ] Wszystkie istniejące TCA features (`GymRoomFeature`, `JoinLiveClassFeature`) działają **bez modyfikacji**
- [ ] UI (`AthleteTileView`, layout, animacje) **bez zmian**
- [ ] Krótki note `PLANS/IPAD-0087-F-known-issues.md` z empirycznym BLE limit observed na real devices (2026)

---

## 🧠 Świadome ograniczenia

| Pominięte | Czemu w tym tickecie nie robimy |
|---|---|
| Scale do 24+ userów via cloud server | Jeśli BLE empirycznie da nam 15-20 connections, to wystarczy dla typowych boxów; cloud osobny ticket IPAD-0100 |
| Mutual beacon attestation (rotujący token, server-side verify) | Solid auth post-MVP — najpierw walidacja samego transportu |
| Background mode dla iPhone | Workout session aktywna trzyma app live (wystarczy dla PoC, jak w obecnym MC) |
| Encryption (BLE pairing + bonding) | Najpierw plain notify, potem TLS-like pairing |
| Apple TV target | Osobny ticket IPAD-0095, większość kodu reużywalna |

---

## 🏗️ Architektura

### Mapping ról

| Rola | Obecne (MC) | Nowe (BLE) |
|------|-------------|------------|
| iPad | `MCNearbyServiceAdvertiser` | `CBPeripheralManager` — advertises GATT service |
| iPhone | `MCNearbyServiceBrowser` | `CBCentralManager` — scans + connects |
| Service identifier | service type `"mfj-gym"` (Bonjour) | `CBUUID` (custom 128-bit) |
| Discovery | mDNS multicast (wymaga tej samej sieci) | BLE Advertisement (radio direct) |
| Data channel | `MCSession.send(data:)` | GATT characteristic write/notify |
| Connection state | `MCSessionDelegate.didChange` | `CBCentralManagerDelegate.didConnect/disconnect` |

### GATT Service design

```
GymRoom Service (CBUUID custom)
├── HR Stream Characteristic
│   ├── Properties: writeWithoutResponse (iPhone → iPad)
│   ├── Permissions: writeable
│   └── Payload: JSON-encoded HRSamplePayload (~200B, fits w MTU)
└── Discovery Info Characteristic
    ├── Properties: read (iPhone reads when discovered)
    └── Payload: { roomName, sessionId, capacity }
```

### Stos warstwowy (co zostaje, co się zmienia)

```
TCA Feature                  ← GymRoomFeature, JoinLiveClassFeature  ✅ BEZ ZMIAN
   ↓ @Dependency
PeerMirrorClient             ← TCA dependency boundary               ✅ BEZ ZMIAN (API)
   ↓
PeerMirrorService            ← @MainActor orchestrator + AsyncStream ✅ BEZ ZMIAN (logika)
   ↓
PeerMirrorBLEHostSession     ← BLE peripheral (NEW)                  🔄 WYMIANA z MC
PeerMirrorBLEPeerSession     ← BLE central (NEW)                     🔄 WYMIANA z MC
```

**Kluczowy insight**: tylko **2 pliki w HealthHub** są wymieniane. Cały TCA + UI codebase pozostaje nietknięty.

---

## 📦 Subtaski

Subtask F = cała migracja BLE (jeden topic ticket). Wewnątrz F dzieli się na 5 atomowych commitów F.A → F.E (każdy kompilujący się, logicznie zamknięty). Format commit messages: `IPAD-0087-F.X BLE Migration — <konkret>` (X = A/B/C/D/E).

---

### Subtask F.A — GATT service constants + Info.plist + entitlements

**Czas**: ~2 h
**Commit**: `IPAD-0087-F.A BLE Migration — define GATT UUIDs and Bluetooth Info.plist keys`

**Co tworzymy**:
- `SharedModels/Sources/SharedModels/PeerMirror/BLEServiceConstants.swift`:
  - `static let gymRoomServiceUUID = CBUUID(string: "<wygenerowany 128-bit UUID>")`
  - `static let hrStreamCharacteristicUUID = CBUUID(string: "<inny UUID>")`
  - `static let discoveryInfoCharacteristicUUID = CBUUID(string: "<inny UUID>")`
- `WorkoutMirrorLive/Info.plist`:
  - `NSBluetoothAlwaysUsageDescription` (komunikat dla usera "Wykrywamy iPada trenera w sali...")
  - `UIBackgroundModes` += `bluetooth-central` + `bluetooth-peripheral` (poprawka vs oryginalny plan: te keys żyją w Info.plist, NIE w entitlements — Apple od iOS 13 trzyma BLE background modes w Info.plist, entitlements rezerwuje dla capabilities wymagających serwera autoryzacji typu HealthKit/iCloud/Sign in with Apple)
- `WorkoutMirrorLive.entitlements`: BEZ ZMIAN (Bluetooth to common capability, nie wymaga entitlement)

**Acceptance**:
- UUIDs są stałe i deterministyczne (nie generowane runtime — jeden raz wygenerowane przez `uuidgen` w terminalu)
- `HRSamplePayload.size < BLE typical MTU` (185B dla BLE 4.2, 512B dla BLE 5+) — jeśli >185B, dodać fragmentation w Subtask F.B/F.C
- Build clean na iOS i tvOS (przygotowanie pod Apple TV w IPAD-0095)

---

### Subtask F.B — `PeerMirrorBLEHostSession` (iPad as peripheral)

**Czas**: ~6 h
**Commit**: `IPAD-0087-F.B BLE Migration — iPad peripheral session with GATT service`

**Co tworzymy**:
`HealthHub/Sources/HealthHub/PeerMirror/PeerMirrorBLEHostSession.swift`:

```swift
final class PeerMirrorBLEHostSession: NSObject, CBPeripheralManagerDelegate {
    private let peripheralManager: CBPeripheralManager
    private let hrCharacteristic: CBMutableCharacteristic
    private var connectedCentrals: [CBCentral] = []

    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        // wait for .poweredOn → add service → startAdvertising
    }

    func peripheralManager(_ peripheral: CBPeripheralManager,
                          didReceiveWrite requests: [CBATTRequest]) {
        // decode HRSamplePayload → yield to AsyncStream
    }

    func peripheralManager(_ peripheral: CBPeripheralManager,
                          central: CBCentral,
                          didSubscribeTo characteristic: CBCharacteristic) {
        // emit .peerConnected event
    }

    // didUnsubscribeFrom → .peerDisconnected
}
```

**Acceptance**:
- Compile clean
- iPad emituje BLE advertisement (verify przez external scanner — np. **nRF Connect for iOS** lub **LightBlue**)
- Logging: `[BLE-Host] Advertising started`, `[BLE-Host] Central subscribed: <identifier>`, `[BLE-Host] HR received: bpm=X from <identifier>`

---

### Subtask F.C — `PeerMirrorBLEPeerSession` (iPhone as central)

**Czas**: ~6 h
**Commit**: `IPAD-0087-F.C BLE Migration — iPhone central session scanning + writing HR`

**Co tworzymy**:
`HealthHub/Sources/HealthHub/PeerMirror/PeerMirrorBLEPeerSession.swift`:

```swift
final class PeerMirrorBLEPeerSession: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    private let centralManager: CBCentralManager
    private var iPadPeripheral: CBPeripheral?
    private var hrCharacteristic: CBCharacteristic?

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        // wait for .poweredOn → scanForPeripherals(withServices: [gymRoomServiceUUID])
    }

    func centralManager(_ central: CBCentralManager,
                       didDiscover peripheral: CBPeripheral,
                       advertisementData: [String : Any],
                       rssi RSSI: NSNumber) {
        // proximity check: RSSI > -75dBm (~10m)
        // connect(peripheral)
    }

    func centralManager(_ central: CBCentralManager,
                       didConnect peripheral: CBPeripheral) {
        // discoverServices + discoverCharacteristics
        // emit .connected event
    }

    func send(_ payload: HRSamplePayload) {
        // writeValue(JSON-encoded, for: hrCharacteristic, type: .withoutResponse)
    }

    // didDisconnectPeripheral → auto-reconnect attempt
}
```

**Acceptance**:
- Compile clean
- iPhone wykrywa iPada w eterze
- HR samples lecą z iPhone'a do iPada (write characteristic) co ~2s
- Auto-reconnect po utracie connection

---

### Subtask F.D — Update `PeerMirrorClient` + `PeerMirrorService` (swap silnika)

**Czas**: ~3 h
**Commit**: `IPAD-0087-F.D BLE Migration — swap PeerMirrorClient liveValue from MC to BLE`

**Co zmieniamy**:
- `HealthHub/Sources/HealthHub/PeerMirror/PeerMirrorService.swift`:
  - Owns now `PeerMirrorBLEHostSession` + `PeerMirrorBLEPeerSession` zamiast MC versions
  - AsyncStream/orchestration logic — **bez zmian**
- `HealthHub/Sources/HealthHub/PeerMirror/PeerMirrorClient.swift`:
  - API surface (`samplesStream`, `peerEventsStream`, `startAdvertising`, `startBrowsing`, `send`, etc.) — **BEZ ZMIAN**
  - `liveValue` używa nowych BLE sessions
- Delete (lub gate `#if MULTIPEER_FALLBACK`) stare `PeerMirrorHostSession.swift` + `PeerMirrorPeerSession.swift`
  - Decyzja po Subtask F.E — jeśli BLE działa solidnie, delete; jeśli edge cases — keep jako fallback

**Acceptance**:
- `GymRoomFeature` i `JoinLiveClassFeature` kompilują się bez zmian
- Wszystkie istniejące `#Preview` działają (przy odpowiednim `testValue` / `previewValue`)
- `PeerMirrorClient.testValue` zwraca dummy data — nie wymaga BLE w testach

---

### Subtask F.E — Smoke test + empirical capacity check

**Czas**: ~2 h
**Commit**: `IPAD-0087-F.E BLE Migration — smoke test and empirical capacity note`

**Test scenarios** (wszystkie na real devices, NIE symulator — BLE nie działa wiarygodnie w simulatorze):

1. **Cross-network connection**: iPhone na 5G (Wi-Fi wyłączone), iPad na Wi-Fi boxu → połączenie ✅
2. **No-network connection**: iPhone i iPad oba bez Wi-Fi → połączenie ✅ (BLE direct radio)
3. **Multi-user**: 2-3 iPhone'y jednocześnie wysyłają HR → wszystkie tile aktualizują się
4. **Proximity disconnect**: user wychodzi z sali (~30m+) → tile na iPadzie znika w <10s
5. **Stress test capacity**: ile concurrent connections udaje się utrzymać (z dostępnych devices — minimum 3-5 fizycznych iPhone'ów + symulatory)
6. **Background tolerance**: iPhone w kieszeni z aktywnym workout session → HR dalej leci
7. **iPad rotation/sleep**: iPad w foreground (kiosk mode) z dimming display → BLE peripheral dalej advertise

**Dokument do uzupełnienia**: `PLANS/IPAD-0087-F-known-issues.md` z polami:
- BLE concurrent connection limit observed (faktyczna liczba 2026)
- Latency observed (avg, p95)
- Reconnect time after out-of-range
- Battery impact (iPad after 1h class, iPhone after 1h workout)
- Edge cases: BLE permission denied, Bluetooth off mid-class, etc.

**Acceptance**:
- Wideo / screenshot z prawdziwego testu — Twój HR na iPadzie **bez Wi-Fi boxu**
- Decyzja "production ready" lub "wymaga cloud server scale-up" — based on empirical capacity number

---

## 📊 Budżet

| Subtask | Czas | Kategoria |
|---|---|---|
| F.A — GATT constants + Info.plist | 2 h | infra |
| F.B — iPad peripheral (BLE Host) | 6 h | networking |
| F.C — iPhone central (BLE Peer) | 6 h | networking |
| F.D — PeerMirrorClient swap | 3 h | refactor |
| F.E — Smoke test + empirical limits | 2 h | walidacja |
| **TOTAL** | **~19 h (2.5 dnia)** | |

Pasuje do typowego budżetu PoC ticketów (~20h).

---

## 🔒 Po tym tickecie — możliwe kierunki

| Ticket | Co dodaje | Kiedy ma sens |
|---|---|---|
| `IPAD-0095` | Apple TV target — reużycie BLE host + GymRoomView | Po walidacji że BLE działa |
| `IPAD-0096` | iBeacon proximity attestation + rotating token | Gdy chcesz solid anti-spoof auth |
| `IPAD-0097` | Mutual attestation (iPad + iPhone weryfikują się navzajem) | Gdy wprowadzasz monetyzację (paid access) |
| `IPAD-0100` | Cloud relay (Vapor + WebSocket) — cross-network mode dla >BLE-limit userów | Gdy chcesz remote join (post-physical attendance) |
| `IPAD-0098` | BT chest strap fallback (CoreBluetooth) dla userów bez Apple Watcha | Post-PMF |

---

## 🧪 Pułapki do mieć w głowie

1. **MTU negotiation** — iOS negocjuje MTU przy connect (typowo 185-512 bytes BLE 5+). Sprawdzić przed write że `payload.size < negotiatedMTU`. Modern iPhone/iPad 5+ powinien dać 244B+ bezproblemowo.

2. **Bluetooth permission UX** — prompt pojawia się przy pierwszym scan/advertise. JoinLiveClassFeature musi obsłużyć denied state (np. settings link gdy denied).

3. **iPad jako peripheral w background** — Apple chowa Service UUID w "overflow area" gdy app nie jest foreground. Dla nas iPad zawsze foreground (kiosk mode), nie problem.

4. **iPhone w kieszeni** — workout session aktywna trzyma app live (jak w obecnym MC). Background Modes `bluetooth-central` zachowuje BLE connection.

5. **RSSI threshold dla proximity** — `didDiscover advertisementData rssi:` zwraca NSNumber. Dla proximity gating ustaw threshold `> -75dBm` (~10m). Dla open box (~30m) `> -85dBm`.

6. **`didDisconnectPeripheral` może odpalać się przy normalnym out-of-range** — distinguish "intentional disconnect" vs "lost signal". Reconnect logic z exponential backoff (1s, 2s, 4s, ...).

7. **`CBPeripheralManager` state restoration** — gdy iOS suspenduje app, BLE state może być restored. Implement `peripheralManager(_:willRestoreState:)` żeby resume cleanly.

8. **Service UUID conflict** — wybierz custom 128-bit UUID który NIE koliduje ze standardami BT SIG (np. Heart Rate Service `0x180D`). Wygeneruj prywatny przez `uuidgen` w terminalu.

9. **BLE w simulator nie działa wiarygodnie** — wszystkie testy multi-device wymagają **real devices**.

10. **`writeWithoutResponse` vs `writeWithResponse`** — wybieramy `writeWithoutResponse` (faster, brak ack) bo HR samples są **idempotent stream** (jeśli jeden zgubimy, następny i tak zaraz przyjdzie). `writeWithResponse` dla discovery info characteristic (jednorazowe, ważne).

---

## 📚 Referencje

- Apple CoreBluetooth framework: `developer.apple.com/documentation/corebluetooth`
- WWDC 2022 Session 110339 — "Boost performance and security in Core Bluetooth"
- Punch Through Core Bluetooth Guide: `punchthrough.com/core-bluetooth-guide/`
- Twój kod: `HealthHub/PeerMirror/PeerMirrorClient.swift` (API surface do reużycia 1:1)
- Twój kod: `SharedModels/PeerMirror/HRSamplePayload.swift` (payload struct do reużycia)
- Testing helper apps: `nRF Connect for iOS` (Nordic Semiconductor) lub `LightBlue Explorer` (Punch Through) — do debug BLE advertise/scan
