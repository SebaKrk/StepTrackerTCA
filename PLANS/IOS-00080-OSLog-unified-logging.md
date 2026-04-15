# IOS-00080 — OSLog Unified Logging

## Cel

Zastąpienie wszystkich `print()` wywołań przez `Logger` (OSLog) w całym projekcie.
Ujednolicenie logowania przez jeden centralny `AppLogger` dostępny na iOS + watchOS.
Dodanie loggera plikowego (`WorkoutFileLogger`) umożliwiającego przeglądanie logów po treningu bez Maca.

## Referencje

- Apple Unified Logging: `os.Logger`, subsystem + category filtering
- Console.app: filtrowanie po `subsystem:com.ss.WorkoutMirror`
- `WCSession.transferFile()` — gwarantowane dostarczenie pliku Watch → iPhone
- `UIFileSharingEnabled` — dostęp do plików przez iOS Files.app

---

## Branch

`feature/IOS-00080-oslog-unified-logging`

---

## Commity

### A: feat(SharedModels): AppLogger — centralized Logger instances
- `AppLogger.swift` w `SharedModels/Sources/SharedModels/Logging/`
- subsystem: `com.ss.WorkoutMirror` (filtrowanie w Console.app)
- 7 kategorii: `watchSession`, `hrMirror`, `appAW` (Watch) + `session`, `trainingManager`, `wc` (iPhone/Shared) + `bluetooth`
- dostępny na iOS 18 + watchOS 11 — oba targety przez jeden plik

### B: refactor(watch): replace print() → Logger w Watch targets
- `WatchWorkoutSessionClient`: `Logger.watchSession` (`.info` lifecycle, `.error` failures, `.debug` simulator)
- `HRMirrorFeature`: `Logger.hrMirror` (`.info` sessionStateChanged, `.debug` already-running guard, tab selection)
- `AppFeatureAW`: `Logger.appAW` (`.info` workoutConfiguration/workoutStarted/workoutEnded/dismiss)
- `WatchAppDelegate`: `Logger.appAW` (launch log)
- `ExtendedRuntimeClient`: `Logger.appAW` (`.notice` willExpire, `.error` invalidated z błędem)
- `AppViewAW`: `Logger.appAW` (`.info` tab switch)
- `WatchConnectivityClientAW`: `Logger.wc` (`.info` lifecycle, `.debug` stream, `workoutTick` pomijany w logach)

### C: refactor(ios): replace print() → Logger w iPhone targets
- `SessionFeature`: `Logger.session` (`.info` viewDidAppear/mode/startWatchWorkout, `.error` fallback, `.notice` hrTimeout)
- `SessionClient` / `WorkoutModeRouter`: `Logger.session` (`.info` mode-switch, endWorkout/startWorkout no-op)
- `DefaultTrainingManager+iOS`: `Logger.trainingManager` (`.info` mirrored-session/startWatchApp, `.error` queries, decode type per object)
- `TrainingSessionStateControl`: `Logger.trainingManager` (`.info` pause/resume/end, `.notice` no-session guards)

### D: refactor(healthhub): replace print() → Logger w WatchConnectivity
- `DefaultWatchConnectivityManager`: `Logger.wc` (`.info` activation/stop, `.error` not-activated, `.notice` transferUserInfo fallback)
- `WatchConnectivity+Delegate`: `Logger.wc` (`.info` activated/reachability/events, `.error` decode-fail)
- `HKWorkoutSessionDelegate`: `Logger.trainingManager` (`.info` sessionState transitions, didReceiveDataFromRemoteWorkoutSession z liczbą/bajtami)
- `workoutTick` pomijany na obu stronach (send + decode guard) — brak szumu co sekundę

### E: feat(SharedModels): WorkoutFileLogger — file-based logging po treningu
- `WorkoutFileLogger.swift` w `SharedModels/Sources/SharedModels/Logging/`
- `actor WorkoutFileLogger` — thread-safe zapis do Documents directory
- Platform-conditional prefix: `watch_log_*.txt` (watchOS) / `iphone_log_*.txt` (iOS)
- `reset()` — nowy plik na start treningu (timestamp w nazwie)
- `log(_ message: String)` — appends `[HH:mm:ss] message`
- `logHRIfNeeded(bpm: Double)` — throttle 30s (HR nie zapisywany co sekundę)
- `currentFileURL()` — URL do transferu
- Eventy logowane na Watch: `STARTED`, `PAUSED (Watch tap)`, `RESUMED (Watch tap)`, `PAUSED (HealthKit)`, `RESUMED (HealthKit)`, `STOPPED`, `DONE`
- Eventy logowane na iPhone: `STARTED`, `PAUSED`, `RESUMED`, `STOPPED`, `DONE`
- `HRMirrorFeature` (Watch): `logHRIfNeeded` przy każdym `.hrReceived`
- `LiveSessionFeature` (iPhone): `logHRIfNeeded` przy każdym effectiveHR > 0
- Po `DONE` na Watch: `watchClient.transferLogFile()` → `WCSession.transferFile()`
- `WatchConnectivity+Delegate` (iPhone): `session(_:didReceive:)` — odbiera plik, kopiuje do Documents
- `WorkoutMirrorLive/Info.plist`: `UIFileSharingEnabled` + `LSSupportsOpeningDocumentsInPlace` — dostęp przez Files.app

### F: refactor(healthhub): replace print() → Logger w Bluetooth
- `DefaultCentralManager`: `Logger.bluetooth` (`.debug` init/deinit, `.info` init/scan/connect/status)
- `BluetoothStatusActor`: `Logger.bluetooth` (`.debug` init/deinit/stream, `.info` status change, `.notice` no continuation)
- `BluetoothScanActor`: `Logger.bluetooth` (`.debug` init/deinit/stream, `.info` start/stop, `.notice` no continuation, `.debug` yield)
- `CBCentralManagerDelegate`: `Logger.bluetooth` (`.debug` discover, `.info` connect/disconnect, `.error` failToConnect + disconnect z błędem)
- `BluetoothClient` (WorkoutMirrorLive): `Logger.bluetooth` (`.debug` liveValue/streams, `.info` init/scan/connect/disconnect)

---

## Poziomy logowania — konwencja

| Poziom | Kiedy używać |
|--------|-------------|
| `.debug` | Szczegóły implementacyjne (init, deinit, continuation, stream management) |
| `.info` | Normalne zdarzenia lifecyclowe (start, stop, connect, status change) |
| `.notice` | Nienormalne ale nie błędne sytuacje (brak kontynuacji, no-session guard) |
| `.error` | Błędy wymagające uwagi (failToConnect, decode fail, not-activated) |

## Filtrowanie w Console.app

```
subsystem:com.ss.WorkoutMirror category:Bluetooth
subsystem:com.ss.WorkoutMirror category:HRMirror
subsystem:com.ss.WorkoutMirror category:TrainingManager
```

> Wymaga: Watch sieciowo sparowany z Xcode + zakładka "All Messages" (nie "Errors and Faults")
