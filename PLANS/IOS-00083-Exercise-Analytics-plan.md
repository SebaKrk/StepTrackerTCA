# Exercise Analytics Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Per-exercise tracking with HR per phase, typowane WOD scores, and analytics view with charts and drilldown.

**Architecture:** SharedModels gets new enums (`MovementCategory`, `WodScoreResult`, `ScalingType`). AppDatabase gets new `exerciseLogRecords` table. LiveSessionFeature buffers HR samples. PhasePanelFeature records phase timestamps. SummaryFeature captures per-exercise data. New `ExerciseAnalyticsFeature` presents charts and history.

**Tech Stack:** Swift, TCA, SQLiteData (StructuredQueries), SwiftUI Charts, SharedModels SPM, HealthHub SPM, AppDatabase SPM

**Design spec:** `PLANS/IOS-00083-Exercise-Analytics-design.md`

**Key discovery:** `ExerciseType` enum already has `aliases` and `category` properties → no need for `ExerciseDefinition` struct. We refine the existing `WorkoutCategoryNew` enum to CrossFit-specific categories.

---

## File Map

### SharedModels (modify)
- `SharedModels/Sources/SharedModels/SharedEnum/ExerciseType/ExerciseType.swift` — update `WorkoutCategoryNew` → `MovementCategory`, refine categories
- `SharedModels/Sources/SharedModels/SharedModels/PlannedSession/WorkoutSessionResult.swift` — replace `score: String` with `scoreResult: WodScoreResult`

### SharedModels (create)
- `SharedModels/Sources/SharedModels/SharedEnum/MovementCategory/MovementCategory.swift` — new enum
- `SharedModels/Sources/SharedModels/SharedEnum/WodScoreResult/WodScoreResult.swift` — new enum
- `SharedModels/Sources/SharedModels/SharedEnum/ScalingType/ScalingType.swift` — new enum
- `SharedModels/Sources/SharedModels/SharedModels/ExerciseLog/ExerciseLog.swift` — domain model
- `SharedModels/Sources/SharedModels/SharedModels/ExerciseLog/ExerciseLogInput.swift` — input from Summary

### AppDatabase (modify)
- `AppDatabase/Sources/AppDatabase/Schema.swift` — add v5 migration

### AppDatabase (create)
- `AppDatabase/Sources/AppDatabase/Records/ExerciseLogRecord.swift` — @Table + mapping

### WorkoutMirrorLive (modify)
- `WorkoutMirrorLive/FeaturesNew/WorkoutTab/Session/Child/LiveSession/Feature/LiveSessionFeature+State.swift` — add `hrBuffer`
- `WorkoutMirrorLive/FeaturesNew/WorkoutTab/Session/Child/LiveSession/Feature/LiveSessionFeature.swift` — append to hrBuffer
- `WorkoutMirrorLive/FeaturesNew/WorkoutTab/Session/Child/LiveSession/Child/PhasePanel/Feature/PhasePanelFeature+State.swift` — add `phaseTimestamps`
- `WorkoutMirrorLive/FeaturesNew/WorkoutTab/Session/Child/LiveSession/Child/PhasePanel/Feature/PhasePanelFeature.swift` — record timestamps
- `WorkoutMirrorLive/FeaturesNew/WorkoutTab/Session/Child/Summary/Feature/SummaryFeature+State.swift` — add exercise inputs
- `WorkoutMirrorLive/FeaturesNew/WorkoutTab/Session/Child/Summary/Feature/SummaryFeature+Action.swift` — exercise actions
- `WorkoutMirrorLive/FeaturesNew/WorkoutTab/Session/Child/Summary/Feature/SummaryFeature.swift` — save ExerciseLog
- `WorkoutMirrorLive/FeaturesNew/WorkoutTab/Session/Child/Summary/SummaryView.swift` — per-exercise UI

### WorkoutMirrorLive (create)
- `WorkoutMirrorLive/FeaturesNew/WorkoutTab/Session/Client/ExerciseLogClient.swift` — TCA dependency
- `WorkoutMirrorLive/FeaturesNew/WorkoutTab/Session/Client/ExerciseCatalogClient.swift` — matching
- `WorkoutMirrorLive/FeaturesNew/ExerciseAnalytics/Feature/ExerciseAnalyticsFeature.swift`
- `WorkoutMirrorLive/FeaturesNew/ExerciseAnalytics/Feature/ExerciseAnalyticsFeature+State.swift`
- `WorkoutMirrorLive/FeaturesNew/ExerciseAnalytics/Feature/ExerciseAnalyticsFeature+Action.swift`
- `WorkoutMirrorLive/FeaturesNew/ExerciseAnalytics/ExerciseAnalyticsView.swift`
- `WorkoutMirrorLive/FeaturesNew/ExerciseAnalytics/Child/ExerciseDetail/Feature/ExerciseDetailFeature.swift`
- `WorkoutMirrorLive/FeaturesNew/ExerciseAnalytics/Child/ExerciseDetail/ExerciseDetailView.swift`

---

## Task 1: MovementCategory enum + refine ExerciseType.category

**Files:**
- Create: `SharedModels/Sources/SharedModels/SharedEnum/MovementCategory/MovementCategory.swift`
- Modify: `SharedModels/Sources/SharedModels/SharedEnum/ExerciseType/ExerciseType.swift`

- [ ] **Step 1: Create MovementCategory enum**

```swift
// MovementCategory.swift
import Foundation

public enum MovementCategory: String, CaseIterable, Codable, Sendable {
    case strength
    case olympicLifting
    case gymnastics
    case cardio
    case mixed

    public var displayName: String {
        switch self {
        case .strength:       return "Strength"
        case .olympicLifting: return "Olympic Lifting"
        case .gymnastics:     return "Gymnastics"
        case .cardio:         return "Cardio"
        case .mixed:          return "Mixed"
        }
    }

    public var color: Color { /* per-category color for charts */ }
}
```

- [ ] **Step 2: Update ExerciseType.category to return MovementCategory**

Replace `WorkoutCategoryNew` usage in `ExerciseType.swift:230-255`. Map:
- `.strength` → `.strength` (deadlift, backSquat, frontSquat, benchPress, shoulderPress, overheadSquat)
- `.weightlifting` → `.olympicLifting` (snatch, cleanAndJerk, powerClean, powerSnatch, hang variants, thrusters)
- `.crossfit` → `.mixed` (burpees, wallBalls, devilPress, burpeeBoxJumps, airSquat, boxJumps, doubleUnders)
- `.cardio` → `.cardio` (running, rowing, cycling, swimming, assaultBike, skiErg)
- `.kettlebell` → distribute: swing/clean/snatch → `.strength`, pushPress → `.olympicLifting`, turkishGetUp → `.strength`
- `.gymnastics` → `.gymnastics` (pullUps, pushUps, toesToBar, sitUps, handstandPushUps, barMuscleUps, ringMuscleUps, pistolSquats, handstandWalk, ringDips, ropeClimb)

- [ ] **Step 3: Remove old WorkoutCategoryNew enum**

Delete `WorkoutCategoryNew` (lines 259-279). Fix all compilation errors — replace `WorkoutCategoryNew` with `MovementCategory` throughout codebase.

- [ ] **Step 4: Verify SharedModels builds**

Run: `swift build` in SharedModels package.

- [ ] **Step 5: Fix compilation in WorkoutMirrorLive**

Search for all `WorkoutCategoryNew` references and replace with `MovementCategory`. Build full project.

---

## Task 2: WodScoreResult + ScalingType enums

**Files:**
- Create: `SharedModels/Sources/SharedModels/SharedEnum/WodScoreResult/WodScoreResult.swift`
- Create: `SharedModels/Sources/SharedModels/SharedEnum/ScalingType/ScalingType.swift`

- [ ] **Step 1: Create WodScoreResult enum**

```swift
// WodScoreResult.swift
import Foundation

public enum WodScoreResult: Codable, Sendable, Equatable {
    case forTime(time: TimeInterval)
    case timeCap(capSeconds: Int, remainingReps: Int)
    case amrap(rounds: Int, extraReps: Int)
    case forLoad(weight: Double)
    case forReps(reps: Int)
    case completed
    case custom(String)

    public var displayString: String {
        switch self {
        case .forTime(let t):              return t.formattedWodDuration()
        case .timeCap(let cap, let reps):  return "TC \(cap / 60)' + \(reps) reps"
        case .amrap(let r, let extra):     return "\(r) rds + \(extra) reps"
        case .forLoad(let w):              return "\(Int(w)) kg"
        case .forReps(let r):              return "\(r) reps"
        case .completed:                   return "✓"
        case .custom(let s):               return s
        }
    }
}
```

- [ ] **Step 2: Create ScalingType enum**

```swift
// ScalingType.swift
import Foundation

public enum ScalingType: String, Codable, Sendable, CaseIterable {
    case rx
    case scaled
    case rxPlus

    public var displayName: String {
        switch self {
        case .rx:     return "Rx"
        case .scaled: return "Scaled"
        case .rxPlus: return "Rx+"
        }
    }
}
```

- [ ] **Step 3: Verify SharedModels builds**

---

## Task 3: Update WorkoutSessionResult

**Files:**
- Modify: `SharedModels/Sources/SharedModels/SharedModels/PlannedSession/WorkoutSessionResult.swift`
- Create: `SharedModels/Sources/SharedModels/SharedModels/ExerciseLog/ExerciseLogInput.swift`

- [ ] **Step 1: Create ExerciseLogInput (pre-save model)**

```swift
// ExerciseLogInput.swift
import Foundation

/// Per-exercise input collected on the Summary screen.
/// Converted to ExerciseLog domain model at save time.
public struct ExerciseLogInput: Equatable, Codable, Sendable, Identifiable {
    public var id: UUID = UUID()
    public var exerciseType: ExerciseType?
    public var unmatchedName: String?
    public var category: MovementCategory?

    public var plannedReps: String?
    public var plannedWeight: Double?

    public var actualWeight: Double?
    public var actualReps: String?
    public var scaling: ScalingType = .rx
    public var isPR: Bool = false
    public var note: String = ""

    public init(/* all fields */) { ... }
}
```

- [ ] **Step 2: Update WorkoutSessionResult**

Replace `score: String` with `scoreResult: WodScoreResult`. Add `exercises: [ExerciseLogInput]`:

```swift
public struct WorkoutSessionResult: Equatable, Codable, Sendable, Identifiable {
    public var id: UUID = UUID()
    public var name: String
    public var description: String
    public var scoreResult: WodScoreResult
    public var note: String
    public var exercises: [ExerciseLogInput]

    public init(
        name: String,
        description: String,
        scoreResult: WodScoreResult = .completed,
        note: String = "",
        exercises: [ExerciseLogInput] = []
    ) { ... }
}
```

- [ ] **Step 3: Fix all compilation errors**

`WorkoutSessionResult.score` is used in:
- `SummaryFeature.swift` (save flow)
- `SummaryView.swift` (UI bindings)
- `WorkoutPlanScoreRecord.swift` (encoding/decoding)
- `WorkoutPlanScoreDetailView.swift`
- `WorkoutPlanScoreComparisonView.swift`

Replace every `.score` with `.scoreResult.displayString` for display, or `scoreResult` for data.

- [ ] **Step 4: Verify full project builds**

---

## Task 4: ExerciseLog domain model + DB record + migration

**Files:**
- Create: `SharedModels/Sources/SharedModels/SharedModels/ExerciseLog/ExerciseLog.swift`
- Create: `AppDatabase/Sources/AppDatabase/Records/ExerciseLogRecord.swift`
- Modify: `AppDatabase/Sources/AppDatabase/Schema.swift`

- [ ] **Step 1: Create ExerciseLog domain model**

```swift
// ExerciseLog.swift (SharedModels)
public struct ExerciseLog: Identifiable, Equatable, Codable, Sendable {
    public var id: UUID
    public var date: Date
    public var exerciseType: ExerciseType?
    public var unmatchedName: String?
    public var category: MovementCategory?
    public var workoutPlanScoreId: UUID?
    public var wodName: String?
    public var plannedReps: String?
    public var plannedWeight: Double?
    public var actualWeight: Double?
    public var actualReps: String?
    public var scaling: ScalingType
    public var isPR: Bool
    public var avgHeartRate: Double?
    public var maxHeartRate: Double?
    public var phaseStartDate: Date?
    public var phaseEndDate: Date?
    public var timeInPhase: Double?
    public var volumeLoad: Double?
    public var tempoPerRound: Double?
    public var note: String?
    public var editableUntil: Date?
}
```

- [ ] **Step 2: Create ExerciseLogRecord (@Table)**

Follow `WorkoutPlanScoreRecord` pattern. Flat columns — no BLOBs (queryable!).

- [ ] **Step 3: Add v5 migration in Schema.swift**

```swift
migrator.registerMigration("v5_exerciseLog") { db in
    try #sql("""
        CREATE TABLE "exerciseLogRecords" (
          "id"                  TEXT NOT NULL PRIMARY KEY ON CONFLICT REPLACE,
          "date"                TEXT NOT NULL,
          "exerciseType"        TEXT,
          "unmatchedName"       TEXT,
          "category"            TEXT,
          "workoutPlanScoreId"  TEXT,
          "wodName"             TEXT,
          "plannedReps"         TEXT,
          "plannedWeight"       REAL,
          "actualWeight"        REAL,
          "actualReps"          TEXT,
          "scaling"             TEXT NOT NULL DEFAULT 'rx',
          "isPR"                INTEGER NOT NULL DEFAULT 0,
          "avgHeartRate"        REAL,
          "maxHeartRate"        REAL,
          "phaseStartDate"      TEXT,
          "phaseEndDate"        TEXT,
          "timeInPhase"         REAL,
          "volumeLoad"          REAL,
          "tempoPerRound"       REAL,
          "note"                TEXT,
          "editableUntil"       TEXT,
          "createdAt"           TEXT NOT NULL,
          "updatedAt"           TEXT NOT NULL,
          "ckRecordData"        BLOB
        ) STRICT
        """)
    .execute(db)
    try #sql("""
        CREATE INDEX "index_exerciseLogRecords_on_exerciseType"
        ON "exerciseLogRecords"("exerciseType")
        """)
    .execute(db)
    try #sql("""
        CREATE INDEX "index_exerciseLogRecords_on_workoutPlanScoreId"
        ON "exerciseLogRecords"("workoutPlanScoreId")
        """)
    .execute(db)
    try #sql("""
        CREATE INDEX "index_exerciseLogRecords_on_date"
        ON "exerciseLogRecords"("date")
        """)
    .execute(db)
}
```

- [ ] **Step 4: Add domain mapping (ExerciseLogRecord ↔ ExerciseLog)**

- [ ] **Step 5: Verify AppDatabase builds + app launches (migration runs)**

---

## Task 5: ExerciseLogClient + ExerciseCatalogClient

**Files:**
- Create: `WorkoutMirrorLive/FeaturesNew/WorkoutTab/Session/Client/ExerciseLogClient.swift`
- Create: `WorkoutMirrorLive/FeaturesNew/WorkoutTab/Session/Client/ExerciseCatalogClient.swift`

- [ ] **Step 1: Create ExerciseLogClient** (follow WorkoutPlanScoreClient pattern)

```swift
struct ExerciseLogClient: Sendable {
    var save: @Sendable ([ExerciseLog]) async throws -> Void
    var fetchByExerciseType: @Sendable (ExerciseType) async throws -> [ExerciseLog]
    var fetchByWorkoutPlanScoreId: @Sendable (UUID) async throws -> [ExerciseLog]
    var fetchByDateRange: @Sendable (Date, Date) async throws -> [ExerciseLog]
    var fetchAll: @Sendable () async throws -> [ExerciseLog]
}
```

With `liveValue` (database queries) and `testValue` (unimplemented).

- [ ] **Step 2: Create ExerciseCatalogClient** (matching)

```swift
struct ExerciseCatalogClient: Sendable {
    var match: @Sendable (String) -> ExerciseType?
    var categoryFor: @Sendable (ExerciseType) -> MovementCategory
}
```

`liveValue` implements 3-step matching: exact → alias → prefix (using existing `ExerciseType.aliases`).

- [ ] **Step 3: Verify builds**

---

## Task 6: HR bufor w LiveSessionFeature

**Files:**
- Modify: `WorkoutMirrorLive/FeaturesNew/WorkoutTab/Session/Child/LiveSession/Feature/LiveSessionFeature+State.swift`
- Modify: `WorkoutMirrorLive/FeaturesNew/WorkoutTab/Session/Child/LiveSession/Feature/LiveSessionFeature.swift`

- [ ] **Step 1: Add hrBuffer to State**

```swift
// LiveSessionFeature+State.swift — add after workoutMetrics:
var hrBuffer: [(date: Date, bpm: Double)] = []
```

Note: tuple is not Equatable by default. Either wrap in struct or exclude from Equatable.

- [ ] **Step 2: Append to hrBuffer on every workoutMetrics**

In `LiveSessionFeature.swift`, inside `case let .workoutMetrics(data):`, after `let effectiveHR`:

```swift
if effectiveHR > 0 {
    state.hrBuffer.append((Date(), effectiveHR))
}
```

- [ ] **Step 3: Verify builds + test that HR still displays correctly**

---

## Task 7: Phase timestamps w PhasePanelFeature

**Files:**
- Modify: `WorkoutMirrorLive/.../PhasePanel/Feature/PhasePanelFeature+State.swift`
- Modify: `WorkoutMirrorLive/.../PhasePanel/Feature/PhasePanelFeature.swift`

- [ ] **Step 1: Add PhaseTimestamp model + phaseTimestamps array to State**

```swift
// PhasePanelFeature+State.swift
struct PhaseTimestamp: Equatable, Sendable {
    let phaseName: String
    let startDate: Date
    var endDate: Date?
}

var phaseTimestamps: [PhaseTimestamp] = []
```

- [ ] **Step 2: Record timestamps on phase changes**

In reducer:
- On first phase appear → append first PhaseTimestamp
- On "next phase" (with min 5s guard) → close current, append new
- Parent reads `phaseTimestamps` when building ExerciseLog

- [ ] **Step 3: Verify builds**

---

## Task 8: Summary Screen — WodScoreResult input UI

**Files:**
- Modify: `WorkoutMirrorLive/.../Summary/SummaryView.swift`
- Modify: `WorkoutMirrorLive/.../Summary/Feature/SummaryFeature+State.swift`
- Modify: `WorkoutMirrorLive/.../Summary/Feature/SummaryFeature+Action.swift`
- Modify: `WorkoutMirrorLive/.../Summary/Feature/SummaryFeature.swift`

- [ ] **Step 1: Replace score TextField with typed WodScoreResult input**

Per `ExerciseWorkoutType`:
- `.forTime` → time picker or text field
- `.amrap` → rounds + extra reps fields
- `.forTime` with time cap and not completed → timeCap + remaining reps
- `.forLoad` → weight field
- etc.

- [ ] **Step 2: Add per-exercise input section under each WOD**

Pre-fill from `ExerciseSession` + `biologicalSex`. Each exercise shows:
- Name + planned weight/reps (read only)
- Actual weight/reps (editable, pre-filled)
- Scaling dropdown (Rx/Scaled/Rx+)
- PR checkbox

- [ ] **Step 3: Wire up actions for exercise input changes**

- [ ] **Step 4: Verify builds + test in preview**

---

## Task 9: Save ExerciseLog on "Zapisz"

**Files:**
- Modify: `WorkoutMirrorLive/.../Summary/Feature/SummaryFeature.swift`
- Modify: `WorkoutMirrorLive/.../Session/Feature/SessionFeature.swift`

- [ ] **Step 1: Calculate per-phase HR from hrBuffer + phaseTimestamps**

Helper function: filter hrBuffer by phase date range → compute avg/max.

- [ ] **Step 2: Calculate volumeLoad and tempoPerRound**

- `volumeLoad`: parse reps string "21-15-9" → sum (45) × actualWeight
- `tempoPerRound`: scoreResult time / rounds count

- [ ] **Step 3: Build ExerciseLog array and save via ExerciseLogClient**

In `.view(.endWorkoutButtonTapped)` handler, after saving WorkoutPlanScore:
- Map each `ExerciseLogInput` → `ExerciseLog` with computed fields
- Call `exerciseLogClient.save(logs)`

- [ ] **Step 4: Set editableUntil = date + 12h**

- [ ] **Step 5: Verify builds + test full flow: scan → workout → summary → save**

---

## Task 10: ExerciseAnalyticsFeature — main view

**Files:**
- Create: `WorkoutMirrorLive/FeaturesNew/ExerciseAnalytics/Feature/ExerciseAnalyticsFeature.swift`
- Create: `WorkoutMirrorLive/FeaturesNew/ExerciseAnalytics/Feature/ExerciseAnalyticsFeature+State.swift`
- Create: `WorkoutMirrorLive/FeaturesNew/ExerciseAnalytics/Feature/ExerciseAnalyticsFeature+Action.swift`
- Create: `WorkoutMirrorLive/FeaturesNew/ExerciseAnalytics/ExerciseAnalyticsView.swift`

- [ ] **Step 1: Create Feature (State, Action, Reducer)**

State:
- `selectedMonth: Date`
- `exerciseLogs: [ExerciseLog]`
- `sortMode: SortMode` (.frequency, .weight, .volume)
- `@Presents destination: ExerciseDetailFeature.State?`

Actions:
- `view(.onAppear)` → fetch logs for month
- `view(.monthChanged)` → refetch
- `view(.sortChanged)`
- `view(.exerciseTapped(ExerciseType))` → navigate to detail

- [ ] **Step 2: Create View with Movement Balance chart**

SwiftUI Charts: stacked `BarMark` per week, color = `MovementCategory.color`.
Legend with percentages below.

- [ ] **Step 3: Create exercise list below chart**

Sorted list with frequency count, weight, PR badge, trend badge.

- [ ] **Step 4: Wire up navigation to detail**

- [ ] **Step 5: Integrate into Analytics tab or as new tab**

- [ ] **Step 6: Verify builds + test with preview data**

---

## Task 11: ExerciseDetailFeature — drilldown

**Files:**
- Create: `WorkoutMirrorLive/FeaturesNew/ExerciseAnalytics/Child/ExerciseDetail/Feature/ExerciseDetailFeature.swift`
- Create: `WorkoutMirrorLive/FeaturesNew/ExerciseAnalytics/Child/ExerciseDetail/ExerciseDetailView.swift`

- [ ] **Step 1: Create Feature**

State: `exerciseType`, `logs: [ExerciseLog]`, `pr: Double?`

- [ ] **Step 2: Create header (PR, count, avg/max HR)**

- [ ] **Step 3: Weight Progression chart**

SwiftUI Charts: `LineMark` date × actualWeight.

- [ ] **Step 4: Volume per Week chart**

`BarMark` week × sum(volumeLoad).

- [ ] **Step 5: Avg HR per Session chart**

`LineMark` date × avgHeartRate. This is the killer feature chart.

- [ ] **Step 6: History list with navigation to workout**

Each row links via `workoutPlanScoreId` → navigate to training session.

- [ ] **Step 7: Verify builds + test with preview data**

---

## Status (as of 2026-04-27)

### Completed (Tasks 1-11)
- [x] Task 1: MovementCategory enum
- [x] Task 2: WodScoreResult + ScalingType enums
- [x] Task 3: WorkoutSessionResult update + ExerciseLogInput
- [x] Task 4: ExerciseLog model + DB record + migration v5
- [x] Task 5: ExerciseLogClient + ExerciseCatalogClient
- [x] Task 6: HR buffer in LiveSessionFeature
- [x] Task 7: Phase timestamps in PhasePanelFeature
- [x] Task 8: Summary — WodScoreResult input UI + per-exercise section
- [x] Task 9: Summary — save ExerciseLog on Zapisz
- [x] Task 10: ExerciseAnalyticsFeature — main view (integrated into Stats tab as "Exercises" picker)
- [x] Task 11: ExerciseDetailFeature — drilldown with charts

### Post-implementation refinements done
- MovementCategory: fixed `.weightlifting` → `.olympicLifting` in ExtractedWorkout+Mapper
- ExerciseSummary: moved to top-level struct with docs
- ExerciseAnalyticsSortMode: extracted to own file with docs
- `Date()` → `@Dependency(\.date.now)` in ExerciseAnalyticsFeature
- `import Foundation` added where missing
- `.eq(id.uuidString)` → `.eq(id)` fix in ExerciseLogClient
- Picker binding fix in ExerciseAnalyticsView
- SetEntry model added for per-set Strength input
- ExerciseTarget added to ExerciseLogInput (proper unit tracking)
- Rx/Scaled/PR removed from Summary exercise input (auto-computed from data)
- Score always visible with context-aware placeholder (Strength: "Heaviest set (kg)", AMRAP: "Rounds + reps" etc.)
- Score shows placeholder only (no pre-fill "✓") — `.completed` renders as empty
- SetInputFeature created as proper TCA feature (State, Action, Reducer, View) with Cancel/Add
- SummaryFeature uses `@Presents var setInput` for sheet presentation
- Write-back only on `confirmed = true` (Add), not Cancel
- Reducer creates `[SetEntry]` from plan for Strength/Olympic WODs with rounds
- Exercise card is tappable → opens sheet (both Strength and WOD exercises)
- For WOD exercises without sets → creates single SetEntry from actual values on open

### Remaining work (next session)

**Task 12b: Summary exercise section — hide exercises, show button only**
- Remove inline exercise list from Summary
- Replace with single "Edit exercises" button per WOD
- Button opens SetInputFeature sheet with ALL exercises for that WOD
- If user doesn't click → pre-filled values from plan saved automatically
- After user edits and confirms → show read-only markdown table (Textual)
- Clicking the table re-opens sheet for editing

This requires rethinking SetInputFeature:
- Currently: one exercise at a time
- Needed: list of ALL exercises in a WOD, user edits any/all
- SetInputFeature.State needs `exercises: [ExerciseLogInput]` not just `sets: [SetEntry]`
- Grid shows: Exercise name | Reps | Weight (for simple) or per-set rows (for Strength)

**Task 13: Textual (markdown) integration**
- Add `gonzalezreal/textual` SPM dependency
- After user confirms edits → convert exercise data to markdown table
- Render read-only table on Summary using Textual
- Tap table → re-opens SetInputFeature sheet

**Task 14: Navigation wiring**
- ExerciseAnalyticsView → tap exercise → push ExerciseDetailView
- ExerciseDetailView → tap history row → navigate to WorkoutPlanScore/TrainingSession
- Wire ExerciseAnalyticsFeature as proper child of StatsFeature (not standalone store)

**Task 15: Polish**
- PR auto-detection: compare actualWeight with max in ExerciseLog SQL
- Scaling auto-detection: compare actualWeight vs plannedWeight
- Cardio exercises: proper unit display (m/cal/min) from ExerciseTarget
- Empty states for all views
- Localization: PL translations for all new strings

**Task 16: ExerciseLog SQL schema update**
- Add `setsData: Data?` BLOB column for per-set data (JSON-encoded [SetEntry])

### UX Flow (final design, 2026-04-27)

```
Summary (default — no edits):
  WOD 1                       🔵
  AMRAP 25': description...
  Score: [        ]    ← placeholder, e.g. "Rounds + reps"
  [📝 Edit exercises]  ← button, no exercise list visible
  Note                 ⊕

  ↓ user taps "Edit exercises"

Sheet (all exercises for this WOD):
  [Cancel]    WOD 1    [Add]
  ┌──────────────────────────────┐
  │ Pull-ups     [9]  reps       │
  │ Thrusters    [8]  reps [50]kg│
  │ Rowing       [17] cal        │
  └──────────────────────────────┘

  ↓ user taps "Add"

Summary (after edit — read-only markdown table):
  WOD 1                       🔵
  Score: 6 rds + 14
  ┌─────────────────────────────┐
  │ Pull-ups    9 reps          │  ← Textual markdown
  │ Thrusters   8 × 50 kg      │
  │ Rowing      17 cal          │
  └─────────────────────────────┘
  [✏ Edit]                       ← tap re-opens sheet
  Note                 ⊕

For Strength WOD — sheet shows per-set Grid:
  [Cancel]  Bench Press  [Add]
  Set  Reps  kg
  1    [10]  [40]
  2    [10]  [45]
  3    [10]  [50]
  4    [10]  [55]
  5    [10]  [60]
```
- Or: separate `setEntryRecords` table with FK to exerciseLogRecords
- Migration v6

## Self-Review Checklist

- [x] **Spec coverage:** All 7 sections from design spec are covered (MovementCategory, ExerciseLog, Matching, WodScoreResult, Summary UI, Analytics, HR buffer)
- [x] **Placeholder scan:** No TBD/TODO in tasks
- [x] **Type consistency:** `ExerciseLog`, `ExerciseLogInput`, `ExerciseLogRecord`, `ExerciseLogClient` — naming consistent
- [x] **File paths:** All based on actual project structure verified via Glob/Read
- [x] **Existing code:** `ExerciseType.aliases` and `ExerciseType.category` reused — no duplicate `ExerciseDefinition`
- [x] **Dependencies:** Task order respects dependencies (SharedModels → AppDatabase → Clients → Features → UI)
