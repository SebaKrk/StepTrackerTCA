# IOS-00075 — Workout Session Architecture Refactor

## What we built

iPhone-primary workout architecture aligned with WWDC25 guidelines.
iPhone always owns the `HKWorkoutSession` and saves the canonical `HKWorkout`.
Watch acts as a pure HR sensor — streams BPM readings via WatchConnectivity, then discards its own session.

---

## What we fixed

**Duplicate HKWorkout in Health app**
Both iPhone and Watch were independently calling `finishWorkout()`. Watch now calls `discardWorkout()` instead — one workout saved, no duplicates.

**Summary never appeared after workout**
iPhone was calling `discardWorkout()` when it detected Watch was present (`isWatchPrimary = true`), leaving `workout = nil`. The Summary feature waited forever for a non-nil workout. Removed the `isWatchPrimary` flag entirely — iPhone always calls `finishWorkout()`.

**Second workout run received no HR data from Watch**
`incomingWorkoutEventStream` was a `let` stored property — a single `AsyncStream` instance for the whole app lifetime. `AsyncStream` supports only one active iterator. After TCA cancelled the first workout's `for await` effect, the second workout's new `for await` loop on the same stream received no events. Fixed by making `incomingWorkoutEventStream` a computed property that creates a fresh stream on each call (same pattern as `workoutSessionStateStream` in `DefaultWorkoutManager`).

**TCA runtime warning on Watch after workout ended**
`workoutTick` events kept arriving via WatchConnectivity's `transferUserInfo` (guaranteed delivery) for a few seconds after the workout ended. The Watch reducer was blindly forwarding them to `hrMirror` destination which was already `nil`. Added `guard state.hrMirror != nil` before forwarding tick/pause/resume events.

**Erratic behavior on second run (inverted pause/resume)**
`workoutSessionIsRunning` and `metrics` kept stale values from the previous session. Both now reset in `prepareWorkout()`.

**`session.end()` not called if `endCollection` threw on Watch**
Watch's `endCollection` failure left the `HKWorkoutSession` in a zombie state, blocking the next workout. Moved `session.end()` outside the `do/catch` block so it always runs.

**`watchEventStream` effect leak between sessions**
The `for await` effect listening for Watch events had no cancellation ID, so it kept running after workout ended. Added `SessionWatchCancelID.sessionStateStream` and cancelled all 4 streams on `.summary` transition.

---

## Architecture in production

```
Watch available:
  Watch → HKWorkoutSession (HR sensor only)
        → discardWorkout() at end
        → streams hrReading via WatchConnectivity → iPhone

  iPhone → HKWorkoutSession (canonical owner)
         → addSamples([HKQuantitySample]) — injects Watch HR into the workout record
         → finishWorkout() → single HKWorkout saved

Watch unavailable:
  iPhone → HKWorkoutSession
         → HKLiveWorkoutDataSource (auto-detects BT HR sensors: Polar, Wahoo, etc.)
         → finishWorkout()
```

---

## Verified

- ✅ Two consecutive workouts — both receive HR data from Watch
- ✅ Single HKWorkout per session in Health app
- ✅ Summary appears after every workout
- ✅ No TCA runtime warnings on Watch side
- ✅ Simulator: graceful fallback (mirroring/Watch not available)
