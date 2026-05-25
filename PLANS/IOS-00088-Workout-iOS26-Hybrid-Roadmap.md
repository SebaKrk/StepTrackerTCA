# IOS-00088 — Workout iOS 26 Hybrid Architecture Roadmap

## Cel

Refactor workout architecture na **dual-mode Hybrid** pod iOS 26:

- **Tor A — Watch-initiated** (Watch-primary + iPhone mirrored) — kanoniczny Apple WWDC23 pattern z HealthKit native mirroring.
- **Tor B — iPhone-initiated** (iPhone-primary z BLE HR sensor) — nowy WWDC25 native API (`HKLiveWorkoutDataSource` na iPhone).

Plus pełne wdrożenie iOS 26 norm dla workout app: Crash Recovery, App Intents (Lock Screen control), Live Activities, Smart Stack readiness, Liquid Glass UI.

Refaktor obejmuje też **naprawę pre-existing bugów** w obecnym Watch-initiated flow (polling end-flow, WCSession reliability, iOS 26 mirroring rozłączanie).

## Referencje

- **WWDC25 #322** — Track workouts with HealthKit on iOS and iPadOS
- **WWDC23 #10023** — Build a multi-device workout app
- **Wytyczne architektoniczne:** `WorkoutMirrorLive/CLAUDE.md` sekcja "HealthKit Workout Architecture — wytyczne iOS 26" (8 reguł R1-R8)
- **Apple Developer Forums #804276** — iOS 26 mirroring bug (FB20723311)
- **Apple sample code:** `BuildingAWorkoutAppForIPhoneAndIPad.zip`

## Docelowe zachowanie

### Tor A — Watch-initiated (Watch-primary + iPhone mirrored)

```
iPhone  → startWatchApp(toHandle: config)
Watch   → HKWorkoutSession (.primary)
Watch   → session.prepare()                              [R1]
        → countdown 3s (warmup HR sensor)
Watch   → startMirroringToCompanionDevice()
iPhone  ← workoutSessionMirroringStartHandler → mirroredSession
HR      : Watch sensor → sendToRemoteWorkoutSession      [R2]
        → iPhone odbiera w didReceiveDataFromRemoteWorkoutSession
State   : pause/resume/end z dowolnej strony — HealthKit syncuje auto
End     : Watch zapisuje HKWorkout (canonical owner)
        → AsyncSequence query na iPhone wykrywa zapis    [R5]
        → summary natychmiast (bez polling timeout)
```

### Tor B — iPhone-initiated (iPhone-primary z BLE HR sensor)

```
iPhone  → HKWorkoutSession (.primary, iOS 26 native)
        → session.prepare()
        → countdown 3s (warmup BLE pairing)
iPhone  → HKLiveWorkoutDataSource auto-pairs sparowane BLE HR sensors
HR      : BLE sensor → HealthKit auto-collect → builder
State   : pause/resume/end lokalnie via App Intents (lock screen)
End     : iPhone zapisuje HKWorkout via finishWorkout()
Crash   : Scene Delegate recoverActiveWorkoutSession     [R3]
        → rebuild builder.dataSource po recovery
```

## Abstrakcja wspólna

Nowy protokół w `SharedModels`:

```swift
protocol WorkoutSession: Sendable {
    func prepare() async throws
    func start(at date: Date) async throws
    func pause() async throws
    func resume() async throws
    func end() async throws

    var metrics: AsyncStream<WorkoutMetrics> { get }
    var state: AsyncStream<HKWorkoutSessionState> { get }
    var workout: AsyncStream<HKWorkout> { get }   // emit at end via HKAnchoredObjectQueryDescriptor
}
```

Dwie implementacje:

- **`iPhoneWorkoutSession`** (iOS 26+) — używana dla Toru B oraz dla iPhone-strony Toru A (mirrored).
- **`WatchWorkoutSession`** (watchOS 10+) — primary session na Watchu w Torze A.

`DefaultTrainingManager` konsumuje `WorkoutSession` przez `@Dependency`, sam nie trzyma `HKWorkoutSession` bezpośrednio. To eliminuje split między `\.trainingManager` i `\.workoutManager` (legacy/dead path z poprzednich iteracji).

## Dekompozycja na sub-projekty

### Phase 1 — Foundation

#### SP1 — WorkoutSession abstraction + iPhone-primary tor

**Co:**
- Nowy protokół `WorkoutSession` w `SharedModels`.
- Implementacja `iPhoneWorkoutSession` używająca natywnego iOS 26 stacka (`HKWorkoutSession` + `HKLiveWorkoutBuilder` + `HKLiveWorkoutDataSource`).
- Refactor `DefaultTrainingManager` żeby konsumował abstrakcję przez dependency.
- Authorization flow dla iPhone HealthKit. Typy do share/read:
  - **Share:** `HKWorkoutType.workoutType()`, `HKQuantityType(.activeEnergyBurned)`, `HKQuantityType(.distanceWalkingRunning)`, `HKQuantityType(.distanceCycling)`.
  - **Read:** `HKQuantityType(.heartRate)`, `HKQuantityType(.activeEnergyBurned)`, oraz wszystkie distance/cycling types.
- `Info.plist`: `NSHealthShareUsageDescription`, `NSHealthUpdateUsageDescription`.
- Background mode: `workout-processing`.

**Definition of Done:**
- [ ] `WorkoutSession` protocol w `SharedModels` z pełną dokumentacją.
- [ ] `iPhoneWorkoutSession` implementuje protokół, używa `HKWorkoutSession` + `HKLiveWorkoutBuilder` + `HKLiveWorkoutDataSource`.
- [ ] `DefaultTrainingManager` przyjmuje `WorkoutSession` przez `@Dependency`.
- [ ] iPhone-only workout z BLE HR sensor działa end-to-end (manual test na real device z Polar/Wahoo strap).
- [ ] `prepare()` wywołane, countdown 3s zaimplementowany w UI.
- [ ] `Info.plist` + entitlements: workout-processing background mode dodane.
- [ ] Unit testy `iPhoneWorkoutSession` z mocked `HealthStoreClient`.

**Pliki dotykane:** ~10-15. **Wpływ ryzyka:** średnie (nowy tor BLE, manual test wymagany). **Złożoność:** L.
**Depends on:** —

#### SP2 — Fix istniejącego Watch-initiated flow

**Co:**
- **R1:** `session.prepare()` PRZED `startMirroringToCompanionDevice()` w `WatchWorkoutSessionClient.start()`.
- **R5:** `HKAnchoredObjectQueryDescriptor.results(for:)` AsyncSequence zamiast pollingu w `TrainingSessionStateControl.handleWorkoutEndIOS()`.
- **R2:** Migracja **lifecycle state events** z WCSession do `sendToRemoteWorkoutSession`. Mapowanie `WatchWorkoutEvent` enum cases:
  - Migrowane (HealthKit channel): `workoutStarted`, `workoutPaused`, `workoutResumed`, `workoutEnded`, `workoutSaved`.
  - Pozostają w WCSession (custom dane aplikacji): `countdownFinished`, `workoutTick`, `maxHRUpdated`, fazy treningu, notatki z planu.
  - **Już** w HealthKit channel od IOS-00075: `hrReading` (HR samples) — zostaje bez zmian.

**Definition of Done:**
- [ ] `WatchWorkoutSessionClient.start()` wywołuje `session.prepare()` przed `startMirroringToCompanionDevice`.
- [ ] `TrainingSessionStateControl.handleWorkoutEndIOS` używa `HKAnchoredObjectQueryDescriptor.results(for:)` — zero polling.
- [ ] `WatchWorkoutEvent.workoutPaused`/`Resumed`/`Ended` migrowane na `sendToRemoteWorkoutSession`.
- [ ] `WatchConnectivity` zostaje wyłącznie dla: fazy treningu, notatki z planu, countdown (custom dane aplikacji).
- [ ] Verified manual: iPhone-initiated End dochodzi do Watcha gdy `reachable=false` (rozwiązanie pre-existing bug).
- [ ] Verified manual: end-flow bez 30s timeout, summary pojawia się natychmiast.

**Pliki dotykane:** ~5. **Wpływ ryzyka:** niskie (bug fixy z testami). **Złożoność:** M.
**Depends on:** SP1 (dla wspólnej abstrakcji), ale może być pisane równolegle.

### Phase 2 — Resilience

#### SP3 — Crash Recovery (iPhone Scene Delegate)

**Co:**
- `UIScene.ConnectionOptions.shouldHandleActiveWorkoutRecovery` w `application(_:configurationForConnecting:options:)`.
- `HKHealthStore.recoverActiveWorkoutSession` w recovery branch.
- Rebuild `builder.dataSource` po recovery — to się NIE zachowuje (R3).
- Aktualizacja `WorkoutFileLogger` żeby emit `[Recovery]` event w pliku diagnostycznym.

**Definition of Done:**
- [ ] Scene Delegate implementuje recovery branch.
- [ ] `WorkoutManager.recover(session:)` public method.
- [ ] `builder.dataSource` ponownie ustawiany po recovery.
- [ ] Manual test: kill app podczas treningu → relaunch → workout kontynuuje z poprawnymi metrykami.
- [ ] `WorkoutFileLogger` emit `[Recovery]` event w pliku.

**Pliki dotykane:** ~3 nowe + `Info.plist`. **Wpływ ryzyka:** niskie. **Złożoność:** S.
**Depends on:** SP1.

### Phase 3 — User-facing iOS 26

#### SP4 — Live Activities + Dynamic Island

**Co:**
- Rozszerzenie istniejącego `WorkoutSessionWidget` o `ActivityAttributes` dla workout.
- `ContentState` z HR/duration/kcal/zone/activity type.
- Update z `HKLiveWorkoutBuilder` delegate (`didCollectDataOf`) → push do Activity.
- Lock Screen UI z waveform HR (jeśli możliwe).
- Dynamic Island: compact (HR + duration) + expanded (full metrics + zone).
- **Liquid Glass — wyłącznie dla Activity surfaces** (Lock Screen card, Dynamic Island compact/expanded). Liquid Glass dla **głównych workout views aplikacji** (HRMirrorFeature, ControlsFeature, WorkoutSessionView) idzie w SP6 — nie duplikujemy.

**Definition of Done:**
- [ ] `WorkoutSessionLive` activity w `WorkoutSessionWidget`.
- [ ] `ActivityAttributes.ContentState` model.
- [ ] `HKLiveWorkoutBuilder` delegate pushuje update do Activity przez ActivityKit API.
- [ ] Compact UI w Dynamic Island.
- [ ] Expanded UI z HR zones.
- [ ] Lock Screen UI.
- [ ] Snapshot tests dla wszystkich states (running, paused, post-end).

**Pliki dotykane:** Widget extension + 2-3 pliki. **Wpływ ryzyka:** średnie (nowa target). **Złożoność:** M.
**Depends on:** SP1, SP2.

#### SP5 — App Intents (Lock Screen control)

**Co:**
- `INStartWorkoutIntent` + `INPauseWorkoutIntent` + `INResumeWorkoutIntent` + `INEndWorkoutIntent`.
- `IntentHandler` delegujący do `WorkoutManager`.
- App Shortcuts integration (Siri: "Start treningu w MyFitnessJournal").
- AppDelegate `handlerFor intent:`.

**Definition of Done:**
- [ ] `IntentHandler` dla wszystkich 4 `INStartWorkout*` intents.
- [ ] `AppDelegate` routes intents.
- [ ] App Shortcut zarejestrowany.
- [ ] Verified manual: pause/resume z lock screen bez odblokowywania telefonu.
- [ ] Verified: Siri uruchamia trening głosem.

**Pliki dotykane:** ~3 nowe. **Wpływ ryzyka:** niskie. **Złożoność:** S.
**Depends on:** SP1. **Synergia:** często wdrażany razem z SP4 (oba dotyczą Lock Screen UX).

### Phase 4 — Polish + watchOS 26

#### SP6 — Smart Stack readiness + Liquid Glass workout UI

**Co:**
- `HKWorkoutRouteBuilder` integration dla outdoor activities (Smart Stack wymóg).
- Liquid Glass adoption w **głównych workout views aplikacji** (Activity surfaces są w SP4):
  - Watch: `HRMirrorFeature` view, `ControlsFeature` view, `LiveSessionFeature` view.
  - iPhone: `WorkoutSessionView` i child views.
- Weryfikacja `HKWorkoutActivityType` mapping (Smart Stack wymóg).

**Definition of Done:**
- [ ] `HKWorkoutRouteBuilder` integracja dla outdoor.
- [ ] Wszystkie views workout — Liquid Glass adoption.
- [ ] Manual test: Smart Stack workout suggestion pojawia się na Watchu po kilku treningach.
- [ ] Snapshot tests workout views (przed/po Liquid Glass).

**Pliki dotykane:** UI refactor wielu views. **Wpływ ryzyka:** niskie (kosmetyka, ale szeroki zakres). **Złożoność:** M.
**Depends on:** wszystkie powyższe SP (UI ostatni).

#### SP7 — Test infrastructure + migration plan

**Co:**
- `HealthStoreClient` `@DependencyClient` w `HealthHub` — abstrakcja nad `HKHealthStore` żeby umożliwić testy.
- `testValue` dla całej `WorkoutSession` chain.
- Snapshot tests dla Live Activity (compact, expanded, lock screen).
- Manual test scripts (markdown checklists) dla:
  - BLE pairing flow (Polar, Wahoo).
  - Crash recovery (kill app podczas treningu).
  - Watch ↔ iPhone dual-mode (Tor A i Tor B).
  - Pre-existing bugs regression.
- Migration documentation dla pre-iOS 26 fallback (graceful disable iOS 26 features).

**Definition of Done:**
- [ ] `HealthStoreClient` z `@DependencyClient` w HealthHub.
- [ ] `testValue` dla `WorkoutSession` + obu implementacji.
- [ ] Snapshot tests dla Live Activity.
- [ ] Manual test scripts w `PLANS/IOS-00088-test-scripts.md`.
- [ ] Migration doc dla iOS < 26 (graceful disable App Intents/Live Activities/Crash Recovery).

**Pliki dotykane:** Test setup. **Wpływ ryzyka:** średnie. **Złożoność:** M.
**Depends on:** SP1-SP6 wszystkie.

## Mapa zależności

```
SP1 ──┬──> SP3
      │
      ├──> SP4 ──┐
      │          │
      ├──> SP5 ──┤
      │          ↓
SP2 ──┴───────> SP6 ──> SP7
```

**Równoległe:**
- SP1 || SP2 (2 osoby lub 2 branche, minimalny merge conflict — różne pliki)
- SP3 || SP4 || SP5 (po SP1)

## Ordering rekomendowany

1. **SP1 + SP2 równolegle** — foundation z bug fixami.
2. **SP3** (po SP1) — resilience.
3. **SP4 + SP5 razem** — UX win, demo-able.
4. **SP6** — Liquid Glass + Smart Stack readiness.
5. **SP7** — test infra na końcu, gdy zakres jest stabilny.

## Definition of Done dla całego refactoru

- [ ] Wszystkie 8 reguł z `WorkoutMirrorLive/CLAUDE.md` egzekwowane w kodzie (lint or test).
- [ ] Hybrid mode działa: Watch+iPhone (Tor A) i iPhone+BLE (Tor B) end-to-end.
- [ ] Wszystkie iOS 26 features uruchomione (App Intents, Live Activities, Crash Recovery, Smart Stack-ready, Liquid Glass).
- [ ] Pre-existing bugs naprawione: WC end-flow reliability, polling 30s timeout, iOS 26.0.1 mirroring rozłączanie.
- [ ] Każdy SP w osobnym branchu + PR + samodzielny atomowy commit history.
- [ ] Regresja: dwa kolejne treningi z różnych torów bez interferencji.

## Ryzyka

1. **iOS 26 mirroring bug (FB20723311)** — Apple jeszcze fixuje. Workaround: `prepare()` przed `startMirroring`. Monitor: `didDisconnectFromRemoteDeviceWithError` logs w produkcji.
2. **BLE HR sensor pairing UX** — Apple zakłada że user już sparował device w Settings → Bluetooth. Onboarding flow w aplikacji musi to wyjaśnić (poza scope SP1 — UX consideration).
3. **HealthKit mocking w testach** — `HKHealthStore` jest hard-to-mock. SP7 musi to ogarnąć, inaczej pozostałe SP będą miały słabe pokrycie testowe.
4. **Watch app installation reliability** — jeśli iOS i watchOS różnią się patch versions (np. 26.0 vs 26.0.1), watch app może nie zainstalować poprawnie. Workaround dla user'ów: ręczna instalacja przez Watch app.
5. **Migration dla iOS < 26 users** — App Intents, Live Activities, Crash Recovery to iOS 26+. Fallback strategy w SP7: gracefully disable, app działa jak dotychczas.
6. **HKLiveWorkoutDataSource + BLE timing** — sparowanie BLE może trwać 1-5s. Bez `prepare()` countdown może być zbyt krótki dla wolnych sensorów. SP1 musi to przetestować na realnym sensorze.

## Out of scope (osobne tickety)

- iPad-specific workout UI (Gym Room kontynuuje w IPAD-0087 / IPAD-0088).
- Workout Buddy integration (Apple internal, brak publicznego API).
- Apple Music integration z workout (osobny ticket).
- visionOS workout (osobny ticket, jeśli kiedykolwiek).
- Audio cues / voice prompts podczas treningu (osobny ticket).
- Strength training set tracker UI changes (kontynuuje w IOS-00084).

## Uwagi operacyjne

- Każdy SP dostaje **osobny brainstorm → spec → plan → implementation cycle** zgodnie ze skillem brainstormingu.
- Spec'i per SP zapisuj jako `PLANS/IOS-00088-SP{N}-<nazwa>-design.md` i odpowiadające `*-plan.md`.
- Każdy subtask SP'a = **atomowy commit** (kompilujący się, logicznie zamknięty), konwencja: `IOS-00088-SP{N}-<X> <Topic> — <konkret>` (sub-id A/B/C/D...).
- Po implementacji każdego SP — review czy CLAUDE.md sekcja "HealthKit Workout Architecture" wymaga aktualizacji (nowa lekcja, której warto utrwalić).
- **Branch konwencja:** `dev/IOS-00088-SP{N}/<short-name>`.
- **Commit'y robi user** — Claude nigdy nie wywołuje `git commit` autonomicznie.

## Status

**Faza:** Brainstorming meta-spec'a — zakończona. Czeka na user review.

**Następny krok po akceptacji:** Brainstorm SP1 (`WorkoutSession` abstraction + iPhone-primary tor) jako osobny cycle.
