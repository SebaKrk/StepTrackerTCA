# IPAD-0087 · Gym Room — Proof of Concept

**Autor**: Sebastian Ściuba
**Data**: 2026-05-22
**Status**: Plan / Backlog

---

## 🎯 Cel

Zobaczyć własne %HR jako kafelek na **iPadzie**, broadcastowane z iPhone'a + Apple Watcha w **lokalnej sieci Wi-Fi**, bez chmury, bez backendu, bez auth.

To jest **walidacja konceptu** — pytanie do którego odpowiada PoC: *"czy wizja TV/iPad-display w boxie CrossFitowym jest technicznie wykonalna i pasuje do user experience'u, który sobie wyobraziłem?"*

---

## ✅ Success criterion (Definition of Done)

- [ ] iPad odpala app → wchodzi bezpośrednio w `GymRoomView`, widoczny "START CLASS" button
- [ ] Tap "START CLASS" → ekran `Waiting for athletes...`, iPad emituje advertisement w LAN (Bonjour `_mfj-gym._tcp`)
- [ ] iPhone w tej samej Wi-Fi → tap "Join Live Class" → iPhone wykrywa iPada, łączy się, startuje workout session na Watchu
- [ ] Na iPadzie pojawia się **kafelek z nickiem + BPM + %HR**, aktualizujący się co ~2 s
- [ ] Drugi iPhone może też dołączyć → drugi kafelek widoczny
- [ ] Tap "END" na iPadzie → wszystkie kafelki znikają, iPhone'y dostają `.disconnected`, Watch workout session kończy się
- [ ] Wszystko działa **bez internetu**, tylko w LAN

---

## 🧠 Świadome ograniczenia PoC

Te rzeczy **celowo pomijamy** w PoC. Każda ma swój follow-up ticket — patrz sekcja "Po PoC" na dole.

| Pominięte | Czemu w PoC niepotrzebne |
|---|---|
| `MCEncryptionPreference.required` (używamy `.none`) | LAN-only PoC, mniej overhead. Production: IPAD-0088 |
| Tile states (`.connecting`/`.stale`/`.lost`) | Tylko `.live` w PoC. Disconnect = kafelek znika natychmiast |
| Stale timer (5s/30s greyout) | Brak — disconnect handled przez delegate |
| Reconnect / retry logic | Idealne Wi-Fi w testach. Production: IPAD-0090 |
| Avatar initials + zone gradients | Solid color z hash nicka wystarczy |
| ENDED state z podsumowaniem | END → od razu IDLE |
| Persystencja klasy / history | Zero zapisu danych |
| HR Zones (5-strefowy system) | %HR sam wystarczy |
| Push notifications "Class started" | iPhone musi otworzyć app i tap Join |
| Apple TV target | iPad wystarczy do walidacji |
| BLE chest strap fallback | Apple Watch wymagany |
| View Facade refactor (każdy element private var) | Inline OK w PoC. Polish później |

---

## 🏗️ Architektura w 1 obrazku

```
[Apple Watch] ──HKLiveWorkoutBuilder──┐
                                      │
                       WCSession      │   (już mamy w HRMirror)
                                      │
[iPhone] ◄────────────────────────────┘
   │
   │  MultipeerConnectivity (LAN, no encryption w PoC)
   │  service type: "mfj-gym"
   │  payload: HRSamplePayload (Codable, ~2s)
   ▼
[iPad] ── GymRoomView ── kafelki athletów
```

Multipeer Connectivity:
- **iPad** = host: `MCNearbyServiceAdvertiser.startAdvertisingPeer()`
- **iPhone** = client: `MCNearbyServiceBrowser.startBrowsingForPeers()`
- Po `foundPeer` → iPhone auto-invituje iPada
- iPad auto-accepts (`invitationHandler(true, session)`)
- Po `.connected` → iPhone forward HR samples co ~2 s

---

## 📦 Subtaski

Każdy subtask = **jeden atomowy commit, kompilujący się i logicznie zamknięty**. Format commit messages: `IPAD-0087-X Gym Room PoC — <konkret>`.

---

### Subtask A — iPad target + Info.plist + scaffold

**Czas**: ~2 h
**Commit**: `IPAD-0087-A Gym Room PoC — enable iPad and configure local network`

**Co dotykamy:**
- `WorkoutMirrorLive` target → aktywuj iPad jako destination
- `WorkoutMirrorLive/Info.plist`:
  - `NSLocalNetworkUsageDescription` = `"Pozwala dołączyć do klasy fitness w boxie."`
  - `NSBonjourServices` = `["_mfj-gym._tcp", "_mfj-gym._udp"]`
  - `UISupportedInterfaceOrientations~ipad` = landscape only
- `WorkoutMirrorLive/WorkoutMirrorLiveApp.swift` conditional routing:
  ```swift
  if UIDevice.current.userInterfaceIdiom == .pad {
      GymRoomView(...)
  } else {
      AppTabView(...)  // istniejący flow
  }
  ```
- `WorkoutMirrorLive/FeaturesNew/GymRoom/View/GymRoomView.swift` placeholder:
  - `"START CLASS"` button na środku, no-op na razie
  - `.onAppear { UIApplication.shared.isIdleTimerDisabled = true }`

**Acceptance:**
- iPad simulator (lub real device) → widoczny tylko ekran "START CLASS"
- Brak crashy, brak warningów

---

### Subtask B — `PeerMirrorClient` + `PeerMirrorService` (minimal)

**Czas**: ~6 h
**Commit**: `IPAD-0087-B Gym Room PoC — add minimal MultipeerConnectivity transport`

**Co tworzymy:**
- `HealthHub/Sources/HealthHub/PeerMirror/PeerMirrorService.swift` — `actor`:
  - Wraps `MCSession(peer:securityIdentity: nil, encryptionPreference: .none)`
    - `// TODO IPAD-0088: switch to .required for production`
  - Wraps `MCNearbyServiceAdvertiser` (host role)
  - Wraps `MCNearbyServiceBrowser` (peer role)
  - Service type constant: `"mfj-gym"`
  - Implementuje `MCSessionDelegate`, `MCNearbyServiceAdvertiserDelegate`, `MCNearbyServiceBrowserDelegate`
  - Auto-accept invitations: `invitationHandler(true, session)`
  - Auto-invite first found peer
- `HealthHub/Sources/HealthHub/PeerMirror/PeerMirrorClient.swift` — `@DependencyClient`:
  - `startAdvertising(displayName: String) async`
  - `stopAdvertising() async`
  - `startBrowsing(displayName: String) async`
  - `stopBrowsing() async`
  - `send(_ payload: HRSamplePayload) async`
  - `samplesStream() -> AsyncStream<HRSamplePayload>`
  - `peerEventsStream() -> AsyncStream<PeerEvent>`
- `HealthHub/Sources/HealthHub/PeerMirror/PeerMirrorClient+Live.swift`:
  - `static let liveValue` z singleton service'em (wzorzec z Twoich existing klientów)
- `SharedModels/Sources/SharedModels/PeerMirror/HRSamplePayload.swift` — `Codable`:
  - `userID: UUID`
  - `nick: String`
  - `bpm: Int`
  - `maxHR: Int`
- `SharedModels/Sources/SharedModels/PeerMirror/PeerEvent.swift` — `enum`:
  - `.connected(peerID: String, nick: String)`
  - `.disconnected(peerID: String)`

**TODO komentarze (osobne tickety):**
```swift
// TODO IPAD-0088: encryptionPreference: .required + cert setup
// TODO IPAD-0089: stale tile timer + .connecting / .stale states
// TODO IPAD-0090: reconnect logic + sample buffering
// TODO IPAD-0094: scale beyond 8 peers (replace MC with Bonjour+WS)
```

**Acceptance:**
- Compile clean (oba targets — iPad i iPhone)
- `testValue` minimal (empty stubs OK na razie)

---

### Subtask C — iPad: `GymRoomFeature` + `GymRoomView`

**Czas**: ~5 h
**Commit**: `IPAD-0087-C Gym Room PoC — iPad reducer and live view`

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
  - Jeśli `!isLive` → `IdleView()` z `Button "START CLASS"`
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
**Commit**: `IPAD-0087-D Gym Room PoC — iPhone join flow and HR forwarding`

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
**Commit**: `IPAD-0087-E Gym Room PoC — smoke test and known issues note`

**Środowisko**: iPad + iPhone + Apple Watch w tej samej Wi-Fi (dom OK).

**Tylko 3 scenariusze:**

1. **Happy path single user**:
   - iPad START → iPhone JOIN → kafelek pojawia się, %HR aktualizuje co ~2 s

2. **Dwóch userów**:
   - Dwa iPhone'y JOIN → 2 kafelki, oba aktualizują się niezależnie

3. **End class**:
   - iPad END → wszystkie kafelki znikają, iPhone'y dostają `.disconnected`, Watch session kończy się

**Świadomie nie testujemy w PoC:**
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

| Subtask | Czas | Kategoria |
|---|---|---|
| A — iPad enable + plist | 2 h | infra |
| B — PeerMirror transport | 6 h | networking |
| C — iPad reducer + view | 5 h | UI + TCA |
| D — iPhone join + forward | 5 h | UI + TCA |
| E — smoke test | 2 h | walidacja |
| **TOTAL** | **~20 h (2.5 dnia)** | |

---

## 🔒 Po PoC zrobimy (osobne tickety)

Każdy z poniższych = osobny ticket po pozytywnej walidacji PoC. Numeracja propozycja, do uzgodnienia przy implementacji.

| # | Ticket | Co dodaje |
|---|---|---|
| 1 | `IPAD-0088` | `MCEncryptionPreference.required` + TLS handshake |
| 2 | `IPAD-0089` | Tile lifecycle states: `.connecting / .live / .stale / .lost` + stale timer |
| 3 | `IPAD-0090` | Reconnect resilience: auto-retry, sample buffer |
| 4 | `IPAD-0091` | UI polish: avatar initials, zone gradients, View Facade refactor, animacje |
| 5 | `IPAD-0092` | HR Zones (5-strefowy system z kolorami) |
| 6 | `IPAD-0093` | ENDED state + class summary (avg HR, time in zones) |
| 7 | `IPAD-0094` | Scale >8 peerów: wymiana MC → Bonjour + WebSocket server |
| 8 | `IPAD-0095` | Apple TV target — reużycie `PeerMirrorClient` + `GymRoomFeature` |
| 9 | `IPAD-0096` | Proactive notifications: APNs/Firebase "Class started" |
| 10 | `IPAD-0097` | Cloud sync (Supabase) — post-class history upload |
| 11 | `IPAD-0098` | BLE chest strap fallback (CoreBluetooth) dla userów bez Apple Watcha |

Sumarycznie ~3-4 tygodnie pracy na pełny produkt. Każdy ticket osobno, w swoim tempie, na fundamencie PoC.

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
4. **iPhone background**: `HKWorkoutSession` aktywna → app trzymana live przez system → MC sesja przeżyje. Bez workout session → MC zerwie w sekundach.
5. **`MCSession` limit 8 peerów** — w PoC nieosiągalne (1-2 users), ale **udokumentowane jako blokada skalowania** → IPAD-0094.
6. **`MCEncryptionPreference.none`** w PoC = świadoma decyzja, oznaczona TODO IPAD-0088.
