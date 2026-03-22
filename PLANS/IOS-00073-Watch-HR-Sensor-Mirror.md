# IOS-00073: Watch App HR Sensor Mirror

## Context

Watch App pełni rolę **sensora HR** dla WorkoutMirrorLive. Kiedy trening startuje na iPhonie, Watch automatycznie wyświetla: aktualne HR (z własnego sensora Watcha), strefę HR, czas treningu.

**Kluczowe decyzje:**
- Watch **nie startuje własnej HKWorkoutSession** — czyta HR przez `HKAnchoredObjectQuery` (live updates)
- Watch **wysyła HR z powrotem do iPhone** via WatchConnectivity (iPhone dostaje precyzyjniejsze dane z sensora Watcha)
- Komunikacja dwukierunkowa przez WatchConnectivity: iPhone → Watch (workout events), Watch → iPhone (HR readings)

---

## Architektura przepływu danych

```
iPhone (WorkoutMirrorLive)
  trening startuje → WorkoutMirroringFeature
  → WatchConnectivityClient.sendWorkoutEvent(.started(type, elapsed))
     ↓ WCSession.sendMessage / transferUserInfo
Watch App
  ← odbiera event → MainFeatureAW → prezentuje HRMirrorFeature
  → HRMirrorFeature startuje HKAnchoredObjectQuery (live HR)
  → Watch wyświetla: HR, strefa HR, elapsed time
  → Watch → iPhone: sendHRReading(bpm) via WCSession.sendMessage
     ↑ iPhone odbiera HR z Watcha → zasila WorkoutMirroringFeature
```

### Mechanizm odczytu HR bez sesji (Watch)

```swift
let query = HKAnchoredObjectQuery(
    type: .heartRate,
    predicate: nil,
    anchor: nil,
    limit: HKObjectQueryNoLimit
) { ... }
query.updateHandler = { _, samples, _, _, _ in
    // yield do AsyncStream → HRMirrorFeature
}
healthStore.execute(query)
```

> Uwaga: bez aktywnej HKWorkoutSession na Watch, Apple Watch próbkuje HR rzadziej (~1/min vs ~1/s w trakcie sesji). Podczas ruchu i przy aktywnej sesji na iPhone częstotliwość rośnie automatycznie.

---

## Co tworzymy / modyfikujemy

### 1. SharedModels — modele wiadomości i HR reading

**Nowy plik:** `SharedModels/Sources/SharedModels/Watch/WatchWorkoutEvent.swift`
```swift
public enum WatchWorkoutEvent: Codable, Sendable {
    case workoutStarted(activityType: UInt, elapsedSeconds: TimeInterval)
    case workoutPaused
    case workoutResumed(elapsedSeconds: TimeInterval)
    case workoutEnded
    case hrReading(bpm: Double, timestamp: Date)  // Watch → iPhone
}
```

### 2. HealthHub — bidirectional WatchConnectivity

**Zmodyfikuj:** `HealthHub/Sources/HealthHub/WatchConnectivity/WatchConnectivityManager.swift`
Dodaj do protokołu:
```swift
func sendWorkoutEvent(_ event: WatchWorkoutEvent) async throws
var incomingWorkoutEventStream: AsyncStream<WatchWorkoutEvent> { get }
```

**Zmodyfikuj:** `HealthHub/Sources/HealthHub/WatchConnectivity/DefaultWatchConnectivityManager.swift`
- `sendWorkoutEvent` → `WCSession.current.sendMessage(encoded, replyHandler: nil)` + fallback `transferUserInfo`
- `incomingWorkoutEventStream` → AsyncStream zasilany w delegate

**Zmodyfikuj:** `WatchConnectivity+Delegate.swift`
- `session(_:didReceiveMessage:)` → decode `WatchWorkoutEvent` → yield do stream
- `session(_:didReceiveUserInfo:)` → analogicznie (fallback gdy niedostępny)

### 3. HRQueryClient (Watch) — odczyt HR bez sesji

**Nowy plik:** `MyFitnessJournal Watch App/Utilities/Client/HRQueryClient.swift`
```swift
struct HRQueryClient {
    var startQuery: () -> AsyncStream<Double>  // stream BPM
    var stopQuery: () -> Void
}
// liveValue: używa HKAnchoredObjectQuery z updateHandler
// @Dependency(\.healthStore)
```

### 4. WatchConnectivityClient (iOS) — rozszerzenie o send/receive

**Zmodyfikuj:** `WorkoutMirrorLive/FeaturesNew/WorkoutTab/Configuration/Client/WatchConnectivityClient.swift`
```swift
// Dodaj:
var sendWorkoutEvent: @Sendable (WatchWorkoutEvent) async -> Void
var incomingEventStream: () -> AsyncStream<WatchWorkoutEvent>  // dla HR z Watcha
```
`liveValue` → `@Dependency(\.watchConnectivityManager)`

### 5. WorkoutMirroringFeature (iOS) — triggerowanie Watcha + odbieranie HR

**Zmodyfikuj:** `WorkoutMirrorLive/Features/WorkoutSession/Child/Mirroring/Feature/WorkoutMirroringFeature.swift`

Dodaj:
- Effect na `onAppear` → `sendWorkoutEvent(.workoutStarted(...))`
- Effect nasłuchujący `incomingEventStream` → `.hrReading(bpm)` → aktualizuje `state.heartRate` (nadpisuje dane z iPhone sensora danymi z Watch)
- Na pause/resume/end → send odpowiedni event

### 6. HRMirrorFeature (Watch) — główny nowy feature

**Nowe pliki:**
```
MyFitnessJournal Watch App/Features/Mirror/
├── Feature/HRMirrorFeature.swift
└── View/HRMirrorView.swift
```

**HRMirrorFeature.swift:**
```swift
@Reducer
struct HRMirrorFeature {
    @ObservableState
    struct State: Equatable {
        var heartRate: Int = 0
        var heartRateZone: HeartRateZone = .resting
        var elapsedSeconds: TimeInterval = 0
        var maxHeartRate: Int = 190
    }
    enum Action {
        case onAppear(startElapsed: TimeInterval, maxHR: Int)
        case hrReceived(Double)
        case elapsedTimeTick
        case endButtonTapped
        case delegate(Delegate)
        enum Delegate { case workoutEnded }
    }
    // Dependencies: HRQueryClient, WatchConnectivityClientAW, WorkoutCalculationsClient
    // Effects:
    // - onAppear → start HRQueryClient.startQuery() → hrReceived stream
    // - onAppear → start Timer.publish(1s) → elapsedTimeTick
    // - hrReceived → calculateZone + sendHRReading via WatchConnectivity
    // - endButtonTapped → sendWorkoutEvent(.workoutEnded) + delegate(.workoutEnded)
}
```

**HRMirrorView.swift — UI (Watch):**
```
┌────────────────────┐
│                    │  <- czarne tło
│     ❤️ 142         │  <- duże, centralne, kolor strefy
│    AEROBOWY        │  <- strefa HR, pill/label
│                    │
│    0:23:41         │  <- elapsed time, szary
│                    │
│   [Zakończ]        │  <- małe, dół
└────────────────────┘
```
- Kolor tekstu HR = kolor strefy (`HeartRateZone.color`)
- Elapsed time: `Text(duration, format: .time(pattern: .hourMinuteSecond))`

### 7. WatchConnectivityClientAW (Watch) — dependency na Watch side

**Nowy plik:** `MyFitnessJournal Watch App/Utilities/Client/WatchConnectivityClientAW.swift`
```swift
struct WatchConnectivityClientAW {
    var sendWorkoutEvent: @Sendable (WatchWorkoutEvent) async -> Void
    var incomingEventStream: () -> AsyncStream<WatchWorkoutEvent>
}
// liveValue → @Dependency(\.watchConnectivityManager)
```

### 8. MainFeatureAW (Watch) — nawigacja do HRMirrorFeature

**Zmodyfikuj:** `MyFitnessJournal Watch App/Features/Main/Feature/MainFeatureAW.swift`

```swift
// Dodaj do Destination:
@Presents var hrMirror: HRMirrorFeature.State?

// Dodaj action:
case watchEventReceived(WatchWorkoutEvent)

// Effect na onAppear: nasłuchuj incomingEventStream
// .workoutStarted → hrMirror = HRMirrorFeature.State(startElapsed:, maxHR:)
// .workoutEnded → hrMirror = nil
```

**Zmodyfikuj:** `MyFitnessJournal Watch App/Features/Main/View/MainViewAW.swift`
```swift
.fullScreenCover(item: $store.scope(state: \.destination?.hrMirror, action: \.destination.hrMirror)) { store in
    HRMirrorView(store: store)
}
```

---

## Plan commitów (atomowe, kompilujące się)

- [ ] `feat(SharedModels): add WatchWorkoutEvent codable enum`
- [ ] `feat(HealthHub): extend WatchConnectivityManager with bidirectional event stream`
- [ ] `feat(watch): add HRQueryClient for HealthKit HR reading without workout session`
- [ ] `feat(watch): add WatchConnectivityClientAW dependency`
- [ ] `feat(ios): extend WatchConnectivityClient with workout event send/receive`
- [ ] `feat(ios): trigger and receive watch events in WorkoutMirroringFeature`
- [ ] `feat(watch): add HRMirrorFeature and HRMirrorView`
- [ ] `feat(watch): wire HRMirrorFeature into MainFeatureAW navigation`

---

## Pliki krytyczne

| Plik | Akcja |
|------|-------|
| `SharedModels/Sources/SharedModels/Watch/WatchWorkoutEvent.swift` | Nowy |
| `HealthHub/.../WatchConnectivity/WatchConnectivityManager.swift` | Modyfikacja |
| `HealthHub/.../WatchConnectivity/DefaultWatchConnectivityManager.swift` | Modyfikacja |
| `HealthHub/.../WatchConnectivity+Delegate/WatchConnectivity+Delegate.swift` | Modyfikacja |
| `WorkoutMirrorLive/.../WatchConnectivityClient.swift` | Modyfikacja |
| `WorkoutMirrorLive/.../WorkoutMirroringFeature.swift` | Modyfikacja |
| `MyFitnessJournal Watch App/.../HRQueryClient.swift` | Nowy |
| `MyFitnessJournal Watch App/.../WatchConnectivityClientAW.swift` | Nowy |
| `MyFitnessJournal Watch App/.../HRMirrorFeature.swift` | Nowy |
| `MyFitnessJournal Watch App/.../HRMirrorView.swift` | Nowy |
| `MyFitnessJournal Watch App/.../MainFeatureAW.swift` | Modyfikacja |
| `MyFitnessJournal Watch App/.../MainViewAW.swift` | Modyfikacja |

---

## Weryfikacja end-to-end

1. iPhone: Start treningu w WorkoutMirrorLive → Watch powinien automatycznie otworzyć HRMirrorView
2. Watch: HR aktualizuje się (w symulatorze: HealthKit Debug → Simulate Data Source)
3. iPhone: `WorkoutMirroringFeature.state.heartRate` zasilany danymi z Watcha (HR reading event)
4. Elapsed time na Watch rośnie prawidłowo
5. Zakończenie treningu na iPhone → Watch wraca do MainView
6. Przycisk "Zakończ" na Watch → Watch wraca do MainView + iPhone otrzymuje event zakończenia
