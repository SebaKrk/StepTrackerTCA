## IOS-00095 — Workout post-mortem: manual link plan & enter results

### Kontekst

Happy path (Watch-primary): `SessionFeature` zbiera HR + phaseTimestamps podczas treningu, po `endWorkout` push'uje `SummaryFeature` (z pre-filled `trainingSession`, `resultInputs`, `hrBuffer`), user wpisuje wyniki + notatki per WOD/exercise, save → `WorkoutPlanScoreRecord` + `[ExerciseLogRecord]`.

Failed path: workout zapisał się w HealthKit (HKWorkout UUID), ale UI flow `.saving → .summary` zawiesił się (WC reachability=false po endWorkout, polling fallback znalazł workout, ale brak `.checkSummary` resolution → user nie zobaczył summary screen → wynik nieprzepisany).

**Cel**: drugi entry point z `History → ActivityDetailsView`:
- Podpnij plan (`trainingSession`) do HKWorkout
- Wpisz wyniki / notatki — **identyczne zachowanie jak happy path** (ten sam `SummaryFeature`)
- Edytuj wynik (gdy plan już podpięty)

### Krytyczne odkrycie z recon

Happy-path model JUŻ MA wszystkie pola dla notatek/wyników:
- `WorkoutSessionResult.note: String` — per-WOD
- `ExerciseLog.note: String?` — per-exercise
- `WorkoutSessionResult.scoreResult: WodScoreResult` — forTime/AMRAP/forLoad/completed

**Schema nie wymaga zmian** (brak migration v8). Praca to **nawigacja + State construction**, nie persistence.

### Architektura

```
ActivityDetailsView
   ├─ planScore == nil:
   │     toolbar "Podpnij plan" → TemplatePickerFeature
   │        → onSelect(trainingSession) → SummaryFeature.State(
   │             summary: builtFromHKWorkout,        // utility B
   │             trainingSession: selected,
   │             hrBuffer: fetchedFromHK,            // utility B
   │             phaseTimestamps: [],                // brak faz w manual
   │             viewState: .successfullyLoaded     // SKIP checkSummary
   │          ) → push SummaryFeature [identyczne UI jak happy path]
   │
   └─ planScore != nil:
         toolbar "Edytuj wynik" → load WorkoutPlanScore
            → SummaryFeature.State(... + resultInputs: zapisane wyniki)
            → push SummaryFeature [edit mode, same UI]
```

### Strategia zmiany w SummaryFeature (krytyczna)

**NIE wprowadzamy mode flag** (`isManualEntry: Bool`). Zamiast tego:
- State już zainicjalizowany z `summary != nil` + `viewState = .successfullyLoaded`
- Reducer `.viewDidAppear` guarduje `.checkSummary` gdy `summary != nil`

To **minimalna zmiana** (1 guard) — bez branching mode, bez duplikacji logiki.

### Subtaski

#### A: SummaryFeature manual init

**Pliki**:
- `SummaryFeature+State.swift` — dodać `public init` przyjmujący pre-filled values
- `SummaryFeature.swift` — guard w `.viewDidAppear`

**Risk**: medium — dotykamy krytycznego happy-path State + reducer. Trzeba zachować backward compat (default empty init nadal działa).

#### B: HKWorkout → WorkoutSummary mapper

**Pliki**:
- `HealthHub/Sources/HealthHub/Workout/WorkoutSummary+FromHKWorkout.swift` (NEW)

**Risk**: low — bezstanowa utility, pure async/await + HKAnchoredObjectQueryDescriptor.

#### C: TemplatePickerFeature

**Pliki**:
- `FeaturesNew/<gdzie?>/TemplatePicker/Feature/TemplatePickerFeature.swift` (NEW)
- `+State.swift`, `+Action.swift`, `View/TemplatePickerView.swift`

**Risk**: low — nowa lekka feature, niezależna od reszty.

#### D: Entry point w ActivityDetailsFeature

**Pliki**:
- `ActivityDetailsFeature+Destination.swift` — case `.linkTemplate`, case `.summary`
- `ActivityDetailsFeature.swift` — actions, reducer, build manual State
- `ActivityDetailsView.swift` — toolbar button, sheet/push

**Risk**: medium — krytyczny screen, ale tylko dodajemy nowe entry point.

#### E: Edit mode

**Pliki**:
- `ActivityDetailsFeature.swift` — load istniejący `WorkoutPlanScore` + decode `resultsData`
- `ActivityDetailsView.swift` — drugi toolbar button "Edytuj wynik"

**Risk**: low — reuse subtaska A logic.

#### F: PL localization

**Pliki**:
- `WorkoutMirrorLive/Localizable.xcstrings`

**Risk**: low.

### Decyzje designerskie (z AskUserQuestion)

1. **Summary location** → "identyczne zachowanie jak happy path" — używamy istniejących pól `WorkoutSessionResult.note` + `ExerciseLog.note`, BRAK nowego `summaryNotes` field
2. **Free workout (bez template'a)** → wymóg podpięcia planu (no plan → no notes)
3. **Start point** → A: Schema → REVISED na A: SummaryFeature manual init (schema niepotrzebny)

### Niezmienniki (R-reguły CLAUDE.md)

- R5 (AsyncStream end-flow) — nie dotykamy
- R3 (Crash Recovery scene delegate) — nie dotykamy
- Stosujemy: `@Presents` + Destination, `@ViewAction`, lokalizacja przez `String(localized:)`, no `@State` w View

### Manual test scripts (po implementacji)

1. **Happy path nadal działa** — start workout watch-primary → end → summary screen otwiera się normalnie z `.saving → .successfullyLoaded`
2. **Manual link** — HKWorkout w History bez planScore → tap → "Podpnij plan" → pick template → summary screen wypełniony, wpisz wynik, save → score zapisany
3. **Edit existing** — HKWorkout z planScore → tap → "Edytuj wynik" → summary screen z pre-filled values, modify, save → zaktualizowane
4. **Cancel manual** — w summary screen tap "Discard" → wraca do ActivityDetails bez zapisu (NIE kasuje HKWorkout — to bug discard flow byłby, tutaj manual entry tylko anuluje wpis)
