# IOS-00085 — Watch session recovery + standalone end

## Context

### Problem
Dnia 2026-05-20 podczas treningu iPhone Sebastiana padł bateryjnie. `HKWorkoutSession` na Apple Watch pozostała w stanie aktywnym (system-level w HK Store), ale **proces Watch app nie miał już sposobu jej zakończyć** — brak Stop button w UI Watch'a. Po naładowaniu obu urządzeń, każda kolejna próba startu nowej sesji z iPhone'a wpadała w stuck state: Watch app nie logowała, `.workoutSaved` nigdy nie przychodziło, polling iPhone'a zwracał `nil` przez 20 prób. Rozwiązaniem było ręczne odinstalowanie Watch app i fresh install z Xcode.

### Root cause
Dwa odrębne braki w Watch app:
1. **Brak recovery flow** — `WorkoutMirrorApp.init` ani `AppFeatureAW.view(.onAppear)` nigdy nie wołają `HKHealthStore.recoverActiveWorkoutSession()`. Stale session zalega w HK Store i blokuje start nowych sesji tego samego typu.
2. **Brak Stop button na Watch** — `HRMirrorView` ma tylko Pause/Resume w `controlsTab`. Jedyna ścieżka do `.stop` w `HRMirrorFeature` to event `.workoutEnded` z iPhone'a (`AppFeatureAW.swift:82-84`). Gdy iPhone unreachable → user nie ma jak zakończyć trening.

### Outcome
Po wdrożeniu:
- Watch app przy każdym starcie wykrywa stuck `HKWorkoutSession` i daje userowi wybór: **Zakończ teraz** / **Odrzuć**. Brak rebuild requirement.
- Watch UI ma własny Stop button (w `controlsTab` obok Pause), z long-press confirmation żeby zabezpieczyć przed przypadkowym kliknięciem.
- Scenariusz „iPhone pada, sesja na Watch trwa" jest w pełni obsługiwany — user kończy na Watch, HKWorkout zapisuje się standalone, iPhone dostaje workout przy następnym sync (HK CloudKit / next launch).

**Out of scope dla tego ticketu** (osobny IOS-00088): „Mode failover Watch→iPhone" gdy Watch pada w trakcie sesji (scenariusz 1 z dyskusji). To wymaga refaktoryzacji mode handlingu (`SessionFeature` + `WorkoutModeRouter` z `SharedModels`) i jest osobnym tematem.

## Architectural overview

```mermaid
flowchart TD
    Start[Watch app launch]
    Recovery{recoverActiveWorkoutSession()?}
    Dialog[Recovery Dialog:<br/>Zakończ / Odrzuć]
    EndR[endSession + workoutSaved → iPhone]
    Discard[discard builder + session.end]
    Normal[Normal flow — wait for iPhone .workoutStarted]
    HRMirror[HRMirrorFeature active]
    UserStop[User taps Stop on Watch UI]
    LongPress{Long-press confirm 1.5s}
    Stop[.stop action — existing flow]
    SaveHK[builder.finishWorkout → HKWorkout saved]
    NotifyiPhone[sendWorkoutEvent(.workoutSaved) — best effort]

    Start --> Recovery
    Recovery -->|YES| Dialog
    Recovery -->|NO| Normal
    Dialog -->|Zakończ| EndR
    Dialog -->|Odrzuć| Discard
    EndR --> Normal
    Discard --> Normal
    Normal --> HRMirror
    HRMirror --> UserStop
    UserStop --> LongPress
    LongPress -->|cancel| HRMirror
    LongPress -->|confirm| Stop
    Stop --> SaveHK
    SaveHK --> NotifyiPhone
```

Recovery i Stop dzielą **ten sam istniejący endpoint:** `watchWorkoutSessionClient.endSession()` → `WatchWorkoutSessionManager.end()` (`WatchWorkoutSessionClient.swift:67-69, 183-200`). To upraszcza implementację — nie tworzymy nowej ścieżki, tylko nowe triggery dla istniejącego flow.

## Feature A: Recovery on Watch app launch

### A1. Rozszerzyć `WatchWorkoutSessionClient`

**Plik:** `WorkoutMirror Watch App/Client/WatchWorkoutSessionClient.swift`

Dodać 2 nowe closure properties (po istniejącym `endSession`):

```swift
/// Sprawdza HK Store pod kątem aktywnej `HKWorkoutSession` z poprzedniej, niezakończonej sesji.
/// Zwraca konfigurację (activityType + startDate) jeśli stuck session istnieje, nil w przeciwnym wypadku.
var checkForStuckSession: @Sendable () async -> StuckSession? = { nil }

/// Przyjmuje stuck session w manager, finalizuje ją: finishWorkout + session.end.
/// Używane przez recovery dialog gdy user wybiera „Zakończ teraz".
var recoverAndEnd: @Sendable () async -> Void = { }

/// Odrzuca stuck session bez zapisywania HKWorkout (discardBuilder).
/// Używane gdy user wybiera „Odrzuć".
var recoverAndDiscard: @Sendable () async -> Void = { }
```

Nowy struct w SharedModels (`SharedModels/Sources/SharedModels/SharedModels/Watch/StuckSession.swift`):
```swift
public struct StuckSession: Sendable, Equatable {
    public let activityTypeRaw: UInt
    public let startDate: Date
    public init(activityTypeRaw: UInt, startDate: Date) { ... }
}
```

W `WatchWorkoutSessionManager` (ten sam plik, prywatny actor):
- Dodać `recoverActiveSession()` — wywołuje `HKHealthStore.recoverActiveWorkoutSession()` (watchOS 9+ API).
- Przy sukcesie: ustaw `self.session = recoveredSession`, attach delegate, **NIE** twórz nowego buildera (recover sam zwraca builder przez `session.associatedWorkoutBuilder()`). Zwróć `StuckSession` z `session.workoutConfiguration.activityType.rawValue` + `session.startDate`.
- `recoverAndEnd` deleguje do istniejącego `end()` — workoutFinished guard zadziała tak samo.
- `recoverAndDiscard` woła `builder.discardWorkout()` (jeśli builder istnieje) + `session.end()` + reset state.

W `liveValue` (`WatchWorkoutSessionClientKey.liveValue`) dorzucić wiring nowych closures do managera.

### A2. Dodać recovery state do `AppFeatureAW`

**Plik:** `WorkoutMirror Watch App/Features/App/Feature/AppFeatureAW+State.swift`

```swift
@Presents var recoveryAlert: RecoveryAlert.State?
```

`RecoveryAlert.State` — prosta struct z `activityType: HKWorkoutActivityType` + `startDate: Date` żeby pokazać kontekst w dialog.

### A3. Trigger recovery check w `view(.onAppear)`

**Plik:** `WorkoutMirror Watch App/Features/App/Feature/AppFeatureAW.swift:113-128`

W istniejącym `case .view(.onAppear)` dorzucić **trzeci** effect (obok 2 istniejących stream'ów):

```swift
.run { [watchWorkoutSessionClient] send in
    guard let stuck = await watchWorkoutSessionClient.checkForStuckSession() else { return }
    await send(.stuckSessionDetected(stuck))
}
```

Dodać dependency `@Dependency(\.watchWorkoutSessionClient) var watchWorkoutSessionClient` w reducerze.

### A4. Handle stuck session detection

**Plik:** `WorkoutMirror Watch App/Features/App/Feature/AppFeatureAW.swift`

Dodać 3 nowe action cases (w `AppFeatureAW+Action.swift`):
- `case stuckSessionDetected(StuckSession)`
- `case recoveryAlert(PresentationAction<RecoveryAlert.Action>)`

W reducerze:
```swift
case let .stuckSessionDetected(stuck):
    Logger.appAW.notice("stuck session detected — activityType=\(stuck.activityTypeRaw), startDate=\(stuck.startDate)")
    state.recoveryAlert = RecoveryAlert.State(stuckSession: stuck)
    return .none

case .recoveryAlert(.presented(.endTapped)):
    return .run { [watchWorkoutSessionClient] send in
        await watchWorkoutSessionClient.recoverAndEnd()
        await send(.recoveryAlert(.dismiss))
    }

case .recoveryAlert(.presented(.discardTapped)):
    return .run { [watchWorkoutSessionClient] send in
        await watchWorkoutSessionClient.recoverAndDiscard()
        await send(.recoveryAlert(.dismiss))
    }

case .recoveryAlert:
    return .none
```

Dodać `.ifLet(\.$recoveryAlert, action: \.recoveryAlert) { RecoveryAlert() }` w body.

### A5. UI dialog

**Plik:** `WorkoutMirror Watch App/Features/App/View/AppViewAW.swift`

Dorzucić `.alert(...)` modifier obserwujący `$store.scope(state: \.recoveryAlert, ...)`. WatchOS-native `.alert` z 2 actions:

```swift
.alert(
    String(localized: "Wykryto niezakończoną sesję"),
    isPresented: $store.scope(state: \.recoveryAlert, ...).isPresented,
    presenting: store.recoveryAlert
) { _ in
    Button(String(localized: "Zakończ teraz")) { send(.recoveryAlert(.endTapped)) }
    Button(String(localized: "Odrzuć"), role: .destructive) { send(.recoveryAlert(.discardTapped)) }
} message: { alert in
    Text(String(localized: "Trening rozpoczęty: \(alert.startDate.formatted(...))"))
}
```

## Feature B: Standalone Stop button on Watch

### B1. Dodać Stop button w UI

**Plik:** `WorkoutMirror Watch App/Features/HRMirror/View/HRMirrorView.swift:108-116`

Obecny `controlsTab` ma tylko `pauseResumeButton`. Zmienić na 2-kolumnowy layout:

```swift
private var controlsTab: some View {
    ZStack {
        Color.black.ignoresSafeArea()
        HStack(spacing: 12) {
            VStack {
                pauseResumeButton
                pauseResumeLabel
            }
            VStack {
                stopButton
                stopButtonLabel
            }
        }
    }
}

private var stopButton: some View {
    Button {
        // Krótki tap nie kończy — wymaga long press
    } label: {
        Image(systemName: "stop.fill")
            .font(.system(size: 26, weight: .semibold))
            .foregroundStyle(.red)
    }
    .buttonStyle(.glass)
    .buttonBorderShape(.circle)
    .controlSize(.large)
    .simultaneousGesture(
        LongPressGesture(minimumDuration: 1.5)
            .onEnded { _ in send(.stopLongPressConfirmed) }
    )
}

private var stopButtonLabel: some View {
    Text(String(localized: "Stop (przytrzymaj)"))
        .font(.caption2.weight(.semibold))
        .foregroundStyle(.red)
}
```

**Czemu long-press:** Apple Watch user często accidental-tapnie podczas treningu (sweaty hands, motion). 1.5s hold to balans między „nie za łatwo" a „nie irytujące". Apple Workout app używa swipe gesture — z Glass button style mamy jednak prostszy long-press, bez konieczności robienia custom swipe view.

### B2. Dodać view action

**Plik:** `WorkoutMirror Watch App/Features/HRMirror/Feature/HRMirrorFeature+Action.swift`

Dodać `case stopLongPressConfirmed` w `@CasePathable enum View`.

### B3. Handle akcję w reducerze

**Plik:** `WorkoutMirror Watch App/Features/HRMirror/Feature/HRMirrorFeature.swift`

W body, dodać przed istniejącym `case .stop:`:

```swift
case .view(.stopLongPressConfirmed):
    Logger.hrMirror.info("Stop confirmed via long-press on Watch")
    return .send(.stop)
```

`.stop` (istniejący case na liniach 217-242) już robi pełen flow: cancel timers + `watchWorkoutSessionClient.endSession()` + `sendWorkoutEvent(.workoutSaved)` + `transferLogFile` + `delegate(.didFinishSaving)`. Nic nie trzeba zmieniać w samym `.stop`.

**Best-effort notify iPhone:** `sendWorkoutEvent(.workoutSaved)` już używa `transferUserInfo` (gwarantowane delivery przez WC queue), więc gdy iPhone reachable → dostanie natychmiast, gdy nie → dostanie przy następnym connect. Bez dodatkowej pracy.

## Critical files — checklist

| Plik | Zmiana |
|------|--------|
| `SharedModels/Sources/SharedModels/SharedModels/Watch/StuckSession.swift` | **NEW** — struct |
| `WorkoutMirror Watch App/Client/WatchWorkoutSessionClient.swift` | 3 nowe closures + manager methods |
| `WorkoutMirror Watch App/Features/App/Feature/AppFeatureAW+State.swift` | `@Presents var recoveryAlert` |
| `WorkoutMirror Watch App/Features/App/Feature/AppFeatureAW+Action.swift` | 2 nowe action cases |
| `WorkoutMirror Watch App/Features/App/Feature/AppFeatureAW.swift` | recovery effect w `.view(.onAppear)` + handle cases |
| `WorkoutMirror Watch App/Features/App/View/AppViewAW.swift` | `.alert` modifier |
| `WorkoutMirror Watch App/Features/HRMirror/Feature/HRMirrorFeature+Action.swift` | `case stopLongPressConfirmed` |
| `WorkoutMirror Watch App/Features/HRMirror/Feature/HRMirrorFeature.swift` | handle `.view(.stopLongPressConfirmed)` → `.send(.stop)` |
| `WorkoutMirror Watch App/Features/HRMirror/View/HRMirrorView.swift` | 2-column controlsTab z stopButton |
| **NEW** `WorkoutMirror Watch App/Features/RecoveryAlert/RecoveryAlert.swift` | mały TCA reducer dla alert state |
| `WorkoutMirrorLive/Localizable.xcstrings` | dodać klucze: „Wykryto niezakończoną sesję", „Zakończ teraz", „Odrzuć", „Trening rozpoczęty:", „Stop (przytrzymaj)" |

## Reused — nie pisać od zera

- `WatchWorkoutSessionManager.end()` (`WatchWorkoutSessionClient.swift:183-200`) — recovery dziedziczy ten sam flow finalization.
- `HRMirrorFeature.stop` case (`HRMirrorFeature.swift:217-242`) — Stop na Watch deleguje do tego samego endpoint.
- `WorkoutFileLogger.shared.log(...)` — wszystkie nowe ścieżki muszą logować (consistency z istniejącym kodem).
- `Logger.appAW`, `Logger.hrMirror`, `Logger.watchSession` — OSLog kategorie już istnieją.

## Verification

### Manual test — Feature A (recovery)

1. Włącz aplikację na iPhone, start workout (np. Cross), poczekaj 30s.
2. Force quit Twojej Watch app (długie naciśnięcie bocznego przycisku Watch → Force Quit z menu apek). To symuluje „iPhone padł / WC umarł".
3. Sprawdź w Apple Workout app czy sesja jest tam jeszcze (potwierdza stuck state).
4. Otwórz Twoją Watch app.
5. **Oczekiwane:** pojawia się alert „Wykryto niezakończoną sesję — Trening rozpoczęty: [czas]" z 2 buttonami.
6. Tap „Zakończ teraz" → alert znika, HKWorkout zapisany w HK Store (sprawdź w Apple Health app po sync z iPhone).
7. Powtórz scenariusz, tap „Odrzuć" → HKWorkout **nie** powinien się pojawić w HK Store.

### Manual test — Feature B (standalone stop)

1. Start workout z iPhone (jak normalnie).
2. **Wyłącz iPhone** (force shutdown, lub airplane mode + zamknij Twoją iOS app — symulacja "iPhone unreachable").
3. Watch UI → przejdź do `controlsTab` (pierwszy tab).
4. **Oczekiwane:** widoczne 2 buttony: Pause/Resume (lewa) i Stop (prawa, czerwona). Pod Stop label „Stop (przytrzymaj)".
5. Krótki tap Stop → nic się nie dzieje (oczekiwane — long-press required).
6. Przytrzymaj Stop button 1.5s → overlay „Saving…" → workout zapisany.
7. Sprawdź w Apple Health app (po włączeniu iPhone'a i sync) → HKWorkout istnieje z correct duration/HR.

### Verification — log file

W każdym manualnym teście, `WorkoutFileLogger` powinien zapisać:
- Feature A: `[Recovery] stuck session detected, activityType=X, startDate=...`, później `STOPPED — ending HealthKit session` (przy „Zakończ teraz") albo `[Recovery] discarded` (przy „Odrzuć").
- Feature B: `[UserAction] Stop long-press confirmed on Watch`, później `STOPPED — ending HealthKit session`.

### Edge cases do sprawdzenia

1. **Recovery alert nie blokuje normalnego startu** — gdy stuck session NIE istnieje, alert się nie pojawia, normal flow startuje bez opóźnienia.
2. **Recovery + nowy start race** — user dostaje recovery alert, ale jednocześnie iPhone wysyła `.workoutStarted`. Sprawdzić że: (a) alert ma priorytet, (b) po decyzji usera nowa sesja startuje czysto.
3. **Long-press cancel** — user zaczyna long-press na Stop, ale puszcza przed 1.5s → nic się nie dzieje (oczekiwane SwiftUI default).
4. **Stop podczas Pause** — gdy workout paused, Stop button też powinien działać (test).
5. **`.workoutSaved` retry przy unreachable iPhone** — wysłany przez `transferUserInfo`, iOS zachowa w kolejce i dostarczy gdy iPhone wróci online. Verify: po Stop na Watch z iPhone wyłączonym, włącz iPhone, otwórz Twoją appkę → `.workoutSaved` powinien przyjść (już bez summary timeout).

## Roboczy timeline

- **Implementacja:** ~4-6h (2 features, czysta architektura, każda zmiana ma jasny endpoint)
- **Testy manualne:** ~1h (oba scenariusze + edge cases)
- **Buffer na bugs / polish:** ~2h

**Razem: 1 dzień roboczy.**

## Dependencies / blockers

- watchOS 9+ minimum (już jest target).
- `HKHealthStore.recoverActiveWorkoutSession()` wymaga `NSHealthShareUsageDescription` w Watch `Info.plist`. **Sprawdzić** czy jest — jeśli nie, dodać przed Feature A (osobny commit). To jest też część P0 release readiness audit z `~/.claude/plans/virtual-toasting-snowglobe.md` (Faza A).
