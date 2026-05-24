# IPAD-0087 · Gym Room — Proof of Concept

**Autor**: Sebastian Ściuba
**Data**: 2026-05-22
**Status**: Plan / Backlog

---

## 🎯 Cel

Zobaczyć własne %HR jako kafelek na **iPadzie**, broadcastowane z iPhone'a + Apple Watcha w **lokalnej sieci Wi-Fi**, bez chmury, bez backendu, bez auth.

To jest **walidacja konceptu** — pytanie do którego odpowiada Proof of Concept: *"czy wizja TV/iPad-display w boxie CrossFitowym jest technicznie wykonalna i pasuje do user experience'u, który sobie wyobraziłem?"*

---

## ✅ Success criterion (Definition of Done)

- [ ] iPad odpala app → wchodzi bezpośrednio w `GymRoomView`, widoczny "START CLASS" button
- [ ] Tap "START CLASS" → ekran `Waiting for athletes...`, iPad emituje advertisement w sieci lokalnej (Bonjour `_mfj-gym._tcp`)
- [ ] iPhone w tej samej Wi-Fi → tap "Join Live Class" → iPhone wykrywa iPada, łączy się, startuje workout session na Watchu
- [ ] Na iPadzie pojawia się **kafelek z nickiem + BPM + %HR**, aktualizujący się co ~2 s
- [ ] Drugi iPhone może też dołączyć → drugi kafelek widoczny
- [ ] Tap "END" na iPadzie → wszystkie kafelki znikają, iPhone'y dostają `.disconnected`, Watch workout session kończy się
- [ ] Wszystko działa **bez internetu**, tylko w sieci lokalnej

---

## 🧠 Świadome ograniczenia Proof of Concept

Te rzeczy **celowo pomijamy** w Proof of Concept. Każda ma swój follow-up ticket — patrz sekcja "Po Proof of Concept" na dole.

| Pominięte | Czemu w Proof of Concept niepotrzebne |
|---|---|
| `MCEncryptionPreference.required` (używamy `.none`) | Sieć lokalna only, mniej overhead. Production: IPAD-0088 |
| Tile states (`.connecting`/`.stale`/`.lost`) | Tylko `.live` w Proof of Concept. Disconnect = kafelek znika natychmiast |
| Stale timer (5s/30s greyout) | Brak — disconnect handled przez delegate |
| Reconnect / retry logic | Idealne Wi-Fi w testach. Production: IPAD-0090 |
| Avatar initials + zone gradients | Solid color z hash nicka wystarczy |
| ENDED state z podsumowaniem | END → od razu IDLE |
| Persystencja klasy / history | Zero zapisu danych |
| HR Zones (5-strefowy system) | %HR sam wystarczy |
| Push notifications "Class started" | iPhone musi otworzyć app i tap Join |
| Apple TV target | iPad wystarczy do walidacji |
| Bluetooth chest strap fallback | Apple Watch wymagany |
| View Facade refactor (każdy element private var) | Inline OK w Proof of Concept. Polish później |

---

## 🏗️ Architektura w 1 obrazku

```
[Apple Watch] ──HKLiveWorkoutBuilder──┐
                                      │
                       WCSession      │   (już mamy w HRMirror)
                                      │
[iPhone] ◄────────────────────────────┘
   │
   │  MultipeerConnectivity (sieć lokalna, no encryption w Proof of Concept)
   │  service type: "mfj-gym"
   │  payload: HRSamplePayload (Codable, ~2s)
   ▼
[iPad] ── GymRoomView ── kafelki athletów
```

MultipeerConnectivity:
- **iPad** = host: `MCNearbyServiceAdvertiser.startAdvertisingPeer()`
- **iPhone** = client: `MCNearbyServiceBrowser.startBrowsingForPeers()`
- Po `foundPeer` → iPhone auto-invituje iPada
- iPad auto-accepts (`invitationHandler(true, session)`)
- Po `.connected` → iPhone forward HR samples co ~2 s

---

## 📦 Subtaski

Każdy subtask = **jeden atomowy commit, kompilujący się i logicznie zamknięty**. Format commit messages: `IPAD-0087-X Gym Room — <konkret>`.

---

### Subtask A — iPad target + Info.plist + scaffold

**Czas**: ~2 h
**Commit**: `IPAD-0087-A Gym Room — enable iPad and configure local network`
**Status**: ✅ DONE

**Co zostało zrobione:**
- `WorkoutMirrorLive` target → iPad jako destination aktywny (manualnie w Xcode UI)
- `WorkoutMirrorLive/Info.plist`:
  - `NSLocalNetworkUsageDescription` dodane
  - `NSBonjourServices` = `["_mfj-gym._tcp", "_mfj-gym._udp"]`
- `WorkoutMirrorLive/WorkoutMirrorLiveApp.swift` conditional routing:
  ```swift
  if UIDevice.current.userInterfaceIdiom == .pad {
      GymRoomView()
  } else {
      AppTabNewView(...)
  }
  ```
- `WorkoutMirrorLive/FeaturesNew/GymRoom/View/GymRoomView.swift` placeholder:
  - "Start class" button na czarnym tle
  - `isIdleTimerDisabled = true` w `.onAppear`, revert w `.onDisappear`
  - View Facade pattern: każdy element jako private var

**Acceptance**: ✅ iPad → "Start class" widoczny, iPhone → istniejący flow nietknięty

---

### Subtask B — `PeerMirrorClient` + `PeerMirrorService` (host/peer separation)

**Czas**: ~6 h
**Commit**: `IPAD-0087-B Gym Room — add MultipeerConnectivity transport with host/peer separation`
**Status**: ✅ DONE (kod zapisany)

**Architektura (zaktualizowana po code review):**

Zamiast jednego actora z trzema rolami, **3 osobne klasy** zgodne ze Swift 6 strict concurrency:

```
HealthHub/Sources/HealthHub/PeerMirror/
├── PeerMirrorHostSession.swift   — host role (iPad), final class : NSObject
├── PeerMirrorPeerSession.swift   — peer role (iPhone), final class : NSObject
├── PeerMirrorService.swift       — @MainActor orchestrator + streams
└── PeerMirrorClient.swift        — TCA dependency (struct: Sendable + DependencyKey)

SharedModels/Sources/SharedModels/PeerMirror/
├── HRSamplePayload.swift         — Codable + Sendable struct
└── PeerEvent.swift               — enum Sendable
```

**Dlaczego nie actor**: `MCSessionDelegate` jest `@objc protocol` → wymaga `NSObject` superclass + delegate methods `nonisolated` (Apple wywołuje z arbitrary queues). Actor by się nie skompilował clean w Swift 6.

**Dlaczego osobne Host/Peer**: każda klasa trzyma `let session: MCSession` (immutable → Sendable-safe across delegate threads). Service re-creates per `start*` call, gwarantując czysty state.

**Co dostarcza `PeerMirrorClient`** (TCA dependency):
- `startAdvertising(displayName:) async`
- `stopAdvertising() async`
- `startBrowsing(displayName:) async`
- `stopBrowsing() async`
- `send(_ payload: HRSamplePayload) async`
- `samplesStream() async -> AsyncStream<HRSamplePayload>`
- `peerEventsStream() async -> AsyncStream<PeerEvent>`

**TODO komentarze w kodzie (osobne tickety):**
- `// TODO IPAD-0088: encryptionPreference: .required + konfiguracja certyfikatu dla produkcji`

**Acceptance**: ✅ Compile clean (HealthHub + SharedModels), brak nowych errorów beyond SourceKit cosmetic

---

### Subtask C — iPad: `GymRoomFeature` + live `GymRoomView`

**Czas**: ~5 h
**Commit**: `IPAD-0087-C Gym Room — iPad reducer and live view with TCA grid`
**Status**: ✅ DONE

**Co tworzymy:**
- `WorkoutMirrorLive/FeaturesNew/GymRoom/Feature/GymRoomFeature.swift`:
  - State (NON-Equatable, bo zawiera streams w runtime):
    ```swift
    var isLive: Bool = false
    var athletes: IdentifiedArrayOf<AthleteTile> = []
    ```
  - `AthleteTile`: `id (PeerID string), nick, bpm, maxHR` → computed `percentHR: Int`
  - Akcje:
    - `view(.onAppear)` — start observing peer events stream
    - `view(.startTapped)` → `peerMirrorClient.startAdvertising`, `isLive = true`
    - `view(.endTapped)` → `peerMirrorClient.stopAdvertising`, `isLive = false`, `athletes.removeAll()`
    - `internal(.peerConnected(id, nick))` → append tile (placeholder bpm = 0)
    - `internal(.peerDisconnected(id))` → remove tile by id
    - `internal(.sampleReceived(payload))` → update tile's bpm + maxHR
  - `@Dependency(\.peerMirrorClient)`
- `WorkoutMirrorLive/FeaturesNew/GymRoom/View/GymRoomView.swift`:
  - Jeśli `!isLive` → `IdleView()` z `Button "START CLASS"` (już mamy z Subtask A)
  - Jeśli `isLive` → `LiveView()` z headerem + `LazyVGrid(columns: 3 stałe)` z `AthleteTileView` per tile
  - END button w headerze
- `WorkoutMirrorLive/FeaturesNew/GymRoom/View/AthleteTileView.swift`:
  - `VStack`: nick (`.title2`), BIG "%HR" (system rounded, 100pt), `"bpm: \(bpm)"` (`.caption`, opacity 0.6)
  - Solid background color z hash nicka (single color, no gradient)
  - Padding, cornerRadius 24

**Acceptance:**
- SwiftUI Preview pokazuje IdleView i LiveView z 2-3 mock athletami
- Tap START toggle live state
- Disconnect peer event → tile znika z grid

---

### Subtask D — iPhone: `JoinLiveClassFeature` + view

**Czas**: ~5 h
**Commit**: `IPAD-0087-D Gym Room — iPhone join flow with synthetic HR for PoC`
**Status**: ✅ DONE

**Architektura zaktualizowana**: dla Proof of Concept iPhone wysyła **syntetyczny HR**
(timer co 2s, random 120-180 bpm), nie real Watch HR. Real integracja z `WCSession`
HR stream → osobny ticket `IPAD-0099`.

**Pliki utworzone**:
- `WorkoutMirrorLive/FeaturesNew/JoinLiveClass/Feature/JoinLiveClassFeature.swift` + `+State`, `+Action`, `+CancelID`
- `WorkoutMirrorLive/FeaturesNew/JoinLiveClass/View/JoinLiveClassView.swift`
- Update: `AppTabNew/Feature/AppTabNewFeature.swift` (destination case + action handler)
- Update: `AppTabNew/AppTabNewView.swift` (floating button + sheet)

**Bugs naprawione podczas implementacji**:
1. Closure parameter labels — usunięto `displayName:` w call site (closure type używa unnamed)
2. AppStorage keys — usunięto kropki (KVO incompatibility), camelCase zamiast dot-notation
3. **Race condition w `PeerMirrorService`** — refactor z lazy `AsyncStream { ... }` (continuation nil dopóki ktoś nie subscribed) na eager `AsyncStream.makeStream()` w `init()`. Bez tego iPhone delegate emit'ował `.connected` event ale yield był no-op, phase tkwił w `.searching`.

**Co tworzymy:**
- `WorkoutMirrorLive/FeaturesNew/JoinLiveClass/Feature/JoinLiveClassFeature.swift`:
  - State:
    ```swift
    @Shared(.appStorage("nick")) var nick: String = "Athlete-\(Int.random(in: 100...999))"
    var isConnected: Bool = false
    ```
  - Akcje:
    - `view(.joinTapped)` →
      - `peerMirrorClient.startBrowsing(displayName: nick)`
      - `workoutManager.startSession(...)` (istniejący `WorkoutManager` z `HealthHub`)
      - Subscribe to peer events + Watch HR stream
    - `view(.leaveTapped)` →
      - `peerMirrorClient.stopBrowsing`
      - `workoutManager.endSession`
    - `internal(.peerConnected)` → `isConnected = true`
    - `internal(.peerDisconnected)` → `isConnected = false`
    - `internal(.hrFromWatch(Int))` → `peerMirrorClient.send(HRSamplePayload(userID, nick, bpm, maxHR))`
  - `@Dependency(\.peerMirrorClient)`, `@Dependency(\.workoutManager)`
- `WorkoutMirrorLive/FeaturesNew/JoinLiveClass/View/JoinLiveClassView.swift`:
  - Sheet z 3 ekranami w switch:
    - `searching` — ProgressView + "Looking for class..."
    - `connected` — checkmark + "In class, broadcasting %HR..."
    - `disconnected` (default) — opis + "Join Live Class" button
- Entry point: nowy button "Join Live Class" w istniejącym `WorkoutTab` toolbar
  - **Decyzja**: button w toolbar zamiast osobnego taba — szybsze, mniej refactoru AppTab

**Acceptance:**
- Real iPhone device + Watch → tap Join → po 2-3 s `isConnected = true`
- HR samples lecą do iPada co ~2 s

---

### Subtask E — Smoke test na real devices

**Czas**: ~2 h
**Commit**: `IPAD-0087-E Gym Room — smoke test and known issues note`
**Status**: 🕓 NEXT

**Validation na symulatorach (2026-05-23)**: ✅ PASSED
- iPad simulator + iPhone simulator w tej samej Wi-Fi (Mac local network)
- Tap "Start class" na iPad → "LIVE · 0 athletes"
- Tap "Join Live Class" na iPhone → po 1-2s "Broadcasting"
- iPad kafelek "Athlete-675 · 77% · 147 bpm" aktualizuje się co 2s
- Disconnect (Leave / End) działa symetrycznie
- Wszystkie 4 fazy lifecycle MultipeerConnectivity zaobserwowane w logach
  (foundPeer → connecting → connected → received event)

**Środowisko**: iPad + iPhone + Apple Watch w tej samej Wi-Fi (dom OK).

**Tylko 3 scenariusze:**

1. **Happy path single user**:
   - iPad START → iPhone JOIN → kafelek pojawia się, %HR aktualizuje co ~2 s

2. **Dwóch userów**:
   - Dwa iPhone'y JOIN → 2 kafelki, oba aktualizują się niezależnie

3. **End class**:
   - iPad END → wszystkie kafelki znikają, iPhone'y dostają `.disconnected`, Watch session kończy się

**Świadomie nie testujemy w Proof of Concept:**
- iPhone w background (kieszeń)
- Wi-Fi handoff (router restart)
- Force quit app
- Resilience pod większym obciążeniem (>2 userów)

**Dokument**: `PLANS/IPAD-0087-known-issues.md` (też gitignored) — wypełnij po teście:
- Co działa zgodnie z planem
- Co działa dziwnie (latency spikes, occasional disconnects)
- Co zostawiamy do follow-up ticketów

**Acceptance:**
- Krótkie wideo / screenshot z prawdziwego testu — **Twoje %HR widoczne na iPadzie**
- Notatka known-issues uzupełniona

---

## 📊 Budżet

| Subtask | Czas | Kategoria | Status |
|---|---|---|---|
| A — iPad enable + plist | 2 h | infra | ✅ DONE |
| B — PeerMirror transport | 6 h | networking | ✅ DONE |
| C — iPad reducer + view | 5 h | UI + TCA | ✅ DONE |
| D — iPhone join + forward | 5 h | UI + TCA | ✅ DONE |
| E — smoke test on real devices | 2 h | walidacja | 🕓 NEXT |
| **TOTAL** | **~20 h (2.5 dnia)** | | 18 h done / 2 h left |

---

## 🔒 Po Proof of Concept zrobimy (osobne tickety)

Każdy z poniższych = osobny ticket po pozytywnej walidacji Proof of Concept. Numeracja propozycja, do uzgodnienia przy implementacji.

| # | Ticket | Co dodaje |
|---|---|---|
| 1 | `IPAD-0088` | `MCEncryptionPreference.required` + TLS handshake |
| 2 | `IPAD-0089` | Tile lifecycle states: `.connecting / .live / .stale / .lost` + stale timer |
| 3 | `IPAD-0090` | Reconnect resilience: auto-retry, sample buffer |
| 4 | `IPAD-0091` | UI polish: avatar initials, zone gradients, View Facade refactor, animacje |
| 5 | `IPAD-0092` | HR Zones (5-strefowy system z kolorami) |
| 6 | `IPAD-0093` | ENDED state + class summary (avg HR, time in zones) |
| 7 | `IPAD-0094` | Scale >8 peerów: wymiana MultipeerConnectivity → Bonjour + WebSocket server |
| 8 | `IPAD-0095` | Apple TV target — reużycie `PeerMirrorClient` + `GymRoomFeature` |
| 9 | `IPAD-0096` | Proactive notifications: APNs/Firebase "Class started" |
| 10 | `IPAD-0097` | Cloud sync (Supabase) — post-class history upload |
| 11 | `IPAD-0098` | Bluetooth chest strap fallback (CoreBluetooth) dla userów bez Apple Watcha |
| 12 | `IPAD-0099` | **Real Watch HR**: zastąp syntetyczny `tickHR` w `JoinLiveClassFeature` real-time HR samples z `HKWorkoutSession` na Watchu via `WCSession` |

Sumarycznie ~3-4 tygodnie pracy na pełny produkt. Każdy ticket osobno, w swoim tempie, na fundamencie Proof of Concept.

---

## 📚 Referencje

- Apple: `MultipeerConnectivity` framework — `developer.apple.com/documentation/multipeerconnectivity`
- WWDC 2013 Session 708 — "Nearby Networking with Multipeer Connectivity"
- WWDC 2019 Session 713 — "Advances in Networking, Part 2" (Network framework jako modern alternative — relevantne dla IPAD-0094)
- Twój kod: `WorkoutMirror Watch App/Features/HRMirror/` (source HR), `HealthHub/.../WatchConnectivity/` (Watch→iPhone — wzorzec do reużycia w `PeerMirrorService`)

---

## 🧪 Pułapki które trzeba mieć w głowie (z research)

1. **Service type `"mfj-gym"`** musi być ≤15 znaków, lowercase + hyphens (RFC 6335). ✅ 7 chars.
2. **`NSLocalNetworkUsageDescription` + `NSBonjourServices` w Info.plist** — bez tego iOS 14+ silently fail przy discovery, popup się nie pokaże.
3. **Advertising stops gdy iPad app idzie w background** → `isIdleTimerDisabled = true` + force foreground.
4. **iPhone background**: `HKWorkoutSession` aktywna → app trzymana live przez system → MultipeerConnectivity sesja przeżyje. Bez workout session → sesja zerwie w sekundach.
5. **`MCSession` limit 8 peerów** — w Proof of Concept nieosiągalne (1-2 users), ale **udokumentowane jako blokada skalowania** → IPAD-0094.
6. **`MCEncryptionPreference.none`** w Proof of Concept = świadoma decyzja, oznaczona TODO IPAD-0088.
7. **`MCSessionDelegate` jest `@objc protocol`** → wymaga `NSObject` superclass + `nonisolated` delegate methods. Dlatego HostSession/PeerSession są `final class : NSObject`, nie actor.
