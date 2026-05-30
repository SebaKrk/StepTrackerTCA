# IOS-00088 — Manual Test Scripts (SP1–SP6)

**Author:** Sebastian Ściuba
**Created:** 2026-05-29
**Status:** Pre-merge validation checklist dla całego refactoru workout iOS 26 Hybrid

---

## Wymagania

- iPhone real device, iOS 26 (lub aktualny stable SDK)
- Apple Watch sparowany, watchOS 26
- (opcjonalnie) BLE HR strap — Polar H10 / Wahoo TICKR sparowany w iOS Settings → Bluetooth
- Mac z Xcode podłączony, Console.app otwarta z filtrem `subsystem:com.ss.WorkoutMirror`

---

## Test 1 — Watch-primary normal flow (SP1 + SP2-A + SP4)

**Cel:** weryfikacja base flow workouta z Apple Watch jako primary session.

1. Watch na nadgarstku, iPhone w ręce
2. Workout tab → Running / Cycling Outdoor → tap Start
3. **Sprawdź na iPhone**: `WaitingForWatch` screen — szary ring (pulsujący per SP6) + "Rozpoczynam na Apple Watch"
4. **Sprawdź na Watch**: `WorkoutMirror Watch App` uruchamia się automatycznie → countdown overlay 3-2-1
5. **iPhone**: po ~1s przechodzi do countdown 3-2-1 (pink ring + numbers)
6. **Sync sprawdź**: oba urządzenia pokazują countdown ~równocześnie (drift ≤ 1s acceptable)
7. Po countdown=0: oba przechodzą do workout view
8. HR z Watcha pokazuje się na iPhone tile (~1-2s pierwszy sample)
9. Dynamic Island compact: % + BPM widoczne na status bar
10. **Long-press Dynamic Island** → expanded view z metrics + Pause/End buttons (SP5)
11. Pause/Resume na iPhone — works (mainControlButtonTapped)
12. Tap End → summary view pojawia się **<2s** (SP2-B AsyncSequence — nie 30s polling)
13. Health.app: workout zapisany z duration, HR avg/max, calories, distance

**Console logs do zobaczenia:**
```
[Session] viewDidAppear — watchStatus: ready
[Session] Watch-primary mode — launching Watch workout
[Session] startWatchWorkout succeeded — subscribing to mirroredSessionStartedStream
[TrainingManager] MIRRORED SESSION received
[Session] sendWorkoutEvent → countdownStart
[Session] Watch-primary — sending workoutStarted + countdownFinished
🚀 [WorkoutActivityFeature] Starting: <type>
... HR metrics flowing ...
handleWorkoutEndIOS — observing HealthKit for Watch workout
handleWorkoutEndIOS — observed: <UUID>
```

---

## Test 2 — iOS 26.0.1 mirroring stability (SP2-A R1)

**Cel:** weryfikacja że `session.prepare()` przed `startMirroringToCompanionDevice()` zapobiega Apple FB20723311 mirroring disconnect.

1. Watch-primary workout, 5+ min duration
2. Mirroring **nie rozłącza się** w trakcie (no `didDisconnectFromRemoteDeviceWithError` w logach)
3. HR samples flow ciągły przez cały time

---

## Test 3 — Crash recovery (SP3)

**Cel:** weryfikacja że workout state odzyskuje się po app kill.

1. Start workout (Watch + iPhone), poczekaj na live session (~30s)
2. **Force-quit iPhone app** (App Switcher → swipe up na app)
3. Watch dalej leci (HR samples capture'owane przez Watch)
4. Otwórz iPhone app ponownie
5. **Console**:
```
[Session] [Recovery] recovered session (type=..., state=...)
[TrainingManager] [Recovery] re-attaching session
[TrainingManager] [Recovery] state propagated to subscribers
```
6. Watch dalej collectuje HR → eventually save HKWorkout
7. Health.app: workout obecny (Watch saved it)

**Caveat**: full UI auto-navigate do session view defer'd (follow-up ticket). User może wrócić do app i będzie w startowym ekranie, ale Watch flow zapisał workout.

---

## Test 4 — iPhone-initiated End w WC unreachable (SP2-C)

**Cel:** weryfikacja HK channel `.workoutEnded` w Watch-primary.

1. Watch-primary workout aktywny
2. **Wyłącz Bluetooth na iPhone** (Settings → BT off) — WC unreachable
3. Tap End na iPhone (w session view)
4. **PRZED SP2-C**: Watch dalej leciał (.workoutEnded WC event dropped)
5. **PO SP2-C**: Watch otrzymuje `.workoutEnded` via HK mirroring channel (reliable bez BT) → finishWorkout + session.end
6. Watch saves HKWorkout
7. **Console iPhone**:
```
[Session] STOPPED — ending workout
... (without 5× retry — usunięty w SP2-C)
```
8. **Console Watch**:
```
[WatchSession] didReceiveDataFromRemoteWorkoutSession — decoded workoutEnded
[WatchSession] received event → workoutEnded
... normal end flow ...
```

---

## Test 5 — Live Activity Pause/End buttons (SP5)

**Cel:** weryfikacja App Intents bridge z Dynamic Island.

1. Workout aktywny (Watch-primary)
2. Zablokuj iPhone (push side button)
3. Tap Live Activity (Dynamic Island lub Lock Screen card)
4. Expanded view → widoczne 2 buttons: **Pause (white) + End (red)** w bottom region
5. Tap **Pause**:
   - iOS unlocks (biometric/passcode)
   - App opens to session view
   - Workout **pauzuje** (ControlsView pokazuje Resume + paused state)
6. Tap **End** (z poziomu Live Activity):
   - App opens
   - Workout finalize
   - Summary view, HKWorkout saved

**Console**:
```
[Session] .intentPauseRequested  (lub .intentEndRequested)
[Session] .controls.view.mainControlButtonTapped
PAUSED (WorkoutFileLogger)
```

---

## Test 6 — iPhone-standalone z BLE strap (SP1-D + SP1-G — gdy iOS 26 confirmed)

**Cel:** weryfikacja iPhone-only workout bez Watcha.

1. Watch zdjęty z ręki / off
2. iPhone + Polar H10 / Wahoo TICKR sparowane w Settings → BT
3. Workout tab → Running Outdoor → Start
4. `WaitingForWatch` skip, countdown 3-2-1 odpala natychmiast (iPhone-standalone path)
5. BLE pairing handshake podczas countdown
6. Live session: HR z chest strap widoczne (~1-3s warmup)
7. Tap End → summary, HKWorkout saved

**Caveat**: full iPhone-standalone path działa **tylko na iOS 26+** (`iPhoneWorkoutSession` ma `@available(iOS 26.0, *)`). iOS < 26 fallback do legacy `workoutManager` (Watch-as-HR-sensor — wymaga Watch'a).

---

## Test 7 — Regression: stary on-screen flow

**Cel:** weryfikacja że SP1-SP6 nie zepsuły existing UX.

1. Workout normal (Watch + iPhone)
2. Pause **on-screen** (nie Live Activity) → works
3. Resume on-screen → works
4. End on-screen → summary, save
5. IPAD-0087 Gym Room broadcasting (toolbar icon obok HR zones) — nadal działa
6. Plans/Activities flow nieruszany

---

## Test 8 — App lifecycle stress

**Cel:** edge cases dla recovery + Live Activity persistence.

1. Workout aktywny → home button (background)
2. Live Activity persistent (Dynamic Island compact)
3. Otwórz inną app (np. Safari), poczekaj 1 min
4. Return do MyFitnessJournal → session view nadal aktywne, metrics flow
5. Force-quit → otwórz znowu → SP3 recovery → workout state visible

---

## Defer'd test cases (po follow-up ticketach)

- Snapshot tests dla Live Activity (compact, expanded, lock screen) — wymaga `swift-snapshot-testing` library
- Multi-user concurrent (4+ iPhone'y → 1 iPad Gym Room) — separate IPAD-0087-F-known-issues
- iOS < 26 graceful fallback — gdy testing device dostępny
- Auto-navigate to session view po SP3 recovery — wymaga TCA orchestration refactor

---

## Sign-off

- [ ] Test 1 (normal flow) pass
- [ ] Test 2 (iOS 26 mirroring stability) pass
- [ ] Test 3 (crash recovery) pass
- [ ] Test 4 (WC unreachable End) pass
- [ ] Test 5 (Live Activity buttons) pass
- [ ] Test 6 (iPhone-standalone) — defer'd jeśli brak BLE strap'a
- [ ] Test 7 (regression) pass
- [ ] Test 8 (lifecycle stress) pass

**Ready for merge**: po pass Testów 1, 3, 4, 5, 7. Test 6 + 8 są nice-to-have.
