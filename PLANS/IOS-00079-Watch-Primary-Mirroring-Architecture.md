# IOS-00078 — Watch-Primary + Mirroring Architecture

## Cel

Przepisanie architektury sesji treningowej na Watch-primary + iPhone-mirrored,
zgodnie z Apple WWDC23/25 i zachowaniem identycznym do Fitness.app.

## Referencje

- WWDC25 Session 322: "Track Workouts with HealthKit on iOS and iPadOS"
- WWDC23: "Build a multi-device workout app"
- Apple sample code: `BuildingAWorkoutAppForIPhoneAndIPad.zip` (iOS 26.0+, Xcode 26.0+)
- Apple Developer Forums #804276 (bug iOS 26 z mirroring — monitoring)

---

## Docelowe zachowanie

### Jeśli Watch dostępny (Watch-primary + mirroring)
```
iPhone → startWatchApp(with: config)
Watch  → HKWorkoutSession (.primary)
Watch  → startMirroringToCompanionDevice()
iPhone ← workoutSessionMirroringStartHandler → session (.mirrored)
iPhone — session.pause() / resume() / stopActivity() → Watch reaguje automatycznie
Watch  — session.pause() → iPhone reaguje automatycznie
Watch  → sendToRemoteWorkoutSession(hrData) → iPhone odbiera HR
Watch  → zapisuje HKWorkout do Health (Watch jest właścicielem)
```

### Jeśli Watch niedostępny (iPhone-primary standalone, iOS 26)
```
iPhone → HKWorkoutSession (.primary, iOS 26)
iPhone → HKLiveWorkoutDataSource → BT HR sensor (automatyczny)
iPhone → zapisuje HKWorkout do Health
```

---

## Zmiany architektoniczne

### Co zostaje (bez zmian)
- `WatchConnectivityClient` / `WatchConnectivityClientAW` — do custom eventów
  (fazy, notatki z planu, countdown events)
- `SessionFeature` TCA — zarządza stanem iPhone
- `HRMirrorFeature` / `AppFeatureAW` — UI na Watch
- `CountDownFeature`, `ControlsFeature`, `LiveSessionFeature` — bez zmian

### Co się zmienia

#### iPhone-side

1. **`DefaultTrainingManager`** staje się głównym managerem sesji na iPhone
   - `workoutSessionMirroringStartHandler` — odbiera mirrored session od Watch
   - `session.pause()` / `resume()` / `stopActivity()` na mirrored session
   - NIE startuje własnej `HKWorkoutSession` gdy Watch dostępny
   - Startuje własną session (iOS 26) gdy Watch niedostępny

2. **`DefaultWorkoutManager`** — używany TYLKO w trybie iPhone-standalone (brak Watcha)
   - Rozważ: czy scalić z `DefaultTrainingManager` jako dwa tryby jednego managera?

3. **`SessionClient`** — nowa closure `controlSession` (pause/resume/stop) operująca
   na mirrored session zamiast WatchConnectivity event

4. **`SessionFeature.viewDidAppear`** — nie przygotowuje już własnej HKWorkoutSession
   gdy Watch dostępny (usuń `selectedWorkout` call w trybie Watch-primary)

#### Watch-side

5. **`WatchWorkoutSessionClient.start()`** — `startMirroringToCompanionDevice()` zostaje
   (jest kluczem architektury) — usunięty błędnie w poprzednim planie

6. **`WatchWorkoutSessionClient`** — dodaje `sendToRemoteWorkoutSession(hrData)`
   zamiast WatchConnectivity dla danych HR

7. **`HRMirrorFeature`** — zamiast `watchConnectivityClientAW.sendWorkoutEvent(.hrReading)`
   używa `sendToRemoteWorkoutSession`

#### Kanały komunikacji po zmianie

| Dane | Przed | Po |
|------|-------|----|
| HR Watch → iPhone | WatchConnectivity | `sendToRemoteWorkoutSession` |
| Pause/Resume iPhone → Watch | WatchConnectivity event | `mirroredSession.pause()` (auto) |
| Pause/Resume Watch → iPhone | WatchConnectivity event | HealthKit mirroring (auto) |
| Fazy/notatki iPhone → Watch | WatchConnectivity | WatchConnectivity (zostaje) |
| Countdown/start events | WatchConnectivity | WatchConnectivity (zostaje) |

---

## Subtaski (atomowe commity)

### Subtask 1 — Refaktor `DefaultTrainingManager` (iPhone-side session handler)
- `workoutSessionMirroringStartHandler` → przechowuje mirrored session
- Ekspozycja `pause()`, `resume()`, `stopActivity()` przez protokół `TrainingManager`
- Nowy `AsyncStream<HKWorkoutSessionState>` na bazie mirrored session delegate
- Nowy `AsyncStream<WorkoutMetrics>` — z `didReceiveDataFromRemoteWorkoutSession`

### Subtask 2 — Refaktor `SessionClient`
- Nowa closure: `controlSession: (SessionControl) async -> Void` (pause/resume/end)
- W trybie Watch-primary: deleguje do `trainingManager.mirroredSession`
- W trybie iPhone-standalone: deleguje do `workoutManager` (bez zmian)
- Usuń `selectedWorkout` call z trybu Watch-primary

### Subtask 3 — Refaktor `SessionFeature` — dual-mode
- Wykrywanie trybu: Watch available → Watch-primary, else → iPhone-primary
- Watch-primary: `startWatchApp` → czekaj na mirrored session
- iPhone-primary: `selectedWorkout` → `prepareWorkout` (obecny kod)
- `controls(.view(.endWorkoutButtonTapped))` → `sessionClient.controlSession(.end)`
  zamiast WatchConnectivity event

### Subtask 4 — Refaktor `WatchWorkoutSessionClient` (Watch-side HR transfer)
- Zamień `watchConnectivityClientAW.sendWorkoutEvent(.hrReading)` 
  na `session.sendToRemoteWorkoutSession(data: encodedHR)`
- `startMirroringToCompanionDevice()` zostaje (jest kluczowy)
- Dodaj `watchOS` availability check

### Subtask 5 — Refaktor `HRMirrorFeature` (Watch-side controls)
- `pause()` / `resume()` → `session.pause()` / `session.resume()` lokalnie na Watch
  (HealthKit automatycznie sync do iPhone — usuń WatchConnectivity events dla pause/resume)
- Zostaw WatchConnectivity dla: countdown, fazy, notatki (custom dane aplikacji)

### Subtask 6 — iPhone-standalone fallback (iOS 26)
- Gdy `watchStatus != .ready` → `DefaultWorkoutManager` (obecny kod, bez zmian)
- Weryfikacja że BT HR sensor działa przez `HKLiveWorkoutDataSource`

### Subtask 7 — Fix `WatchConnectivityClientAW.eventStream` (stream bug)
- Zamień single-consumer stream na fresh stream przy każdym `incomingEventStream()`
  (wzorzec jak `DefaultWatchConnectivityManager.incomingWorkoutEventStream`)

### Subtask 8 — Testy i walidacja
- Test trybu Watch-primary (fizyczne urządzenia)
- Test trybu iPhone-standalone (bez Watch)
- Weryfikacja: jeden HKWorkout w Health (bez duplikatów)
- Weryfikacja: pause/resume sync między urządzeniami

---

## Ryzyka

- **iOS 26 bug #804276**: mirroring session może tracić połączenie z Watch.
  Monitoring: obserwuj log `workoutSession(_:didDisconnectFromRemoteDeviceWithError:)`
- **Brak Watch app na zegarku**: `startWatchApp` rzuci błąd → fallback do iPhone-standalone
- **Czas uruchomienia Watch app**: Watch potrzebuje kilku sekund → countdown na iPhone
  jest naturalnym buforem
- **`sendToRemoteWorkoutSession` vs WatchConnectivity niezawodność**: test na realnych
  urządzeniach pod obciążeniem

---

## Uwagi

- Pobierz `BuildingAWorkoutAppForIPhoneAndIPad.zip` z developer.apple.com przed implementacją
- `DefaultTrainingManager.setupRemoteSessionHandler()` już robi część roboty — zweryfikuj
  czy wystarczy rozbudować zamiast pisać od zera
- Watch saves HKWorkout — user zobaczy trening z perspektywy Watcha w Health.app (OK)
