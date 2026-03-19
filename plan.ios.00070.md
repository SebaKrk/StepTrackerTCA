# IOS-00070: Planned Workout Session (v2)

## Kontekst

Aplikacja ma OCR → `TrainingSession` (z fazami: warmUp, workouts[], coolDown) oraz działającą sesję treningową (`SessionFeature`) opartą na `HKWorkoutSession`. Cele:
1. Zapisanie wyników WODów po treningu (`WorkoutPlanScore`)
2. Powiązanie wyników z `HKWorkout` i `TrainingSession` dla historii i porównań
3. [FURTKA] Pokazanie faz planu podczas sesji live

---

## Modele danych

### `WorkoutPlanScore`

Jeden rekord = jedno wykonanie planu. Powstaje w `SummaryFeature` po zakończeniu sesji.

```swift
public struct WorkoutPlanScore: Identifiable, Equatable, Codable, Sendable {
    public let id: UUID                         // primary key
    public let date: Date                       // snapshot — niezależny od HKWorkout
    public let trainingSessionId: UUID          // → TrainingSession (plan)
    public let hkWorkoutId: UUID                // → HKWorkout (dane zdrowotne)
    public var results: [WorkoutSessionResult]  // tylko WODy — nie warmup/cooldown
}
```

**Dlaczego `date` jako snapshot:** HKWorkout może zostać usunięty z Health. Historia wyników musi żyć niezależnie.

**Relacja:** `TrainingSession` (1) → `WorkoutPlanScore` (wiele) — oś czasu wykonań planu.

---

### `WorkoutSessionResult`

Wynik jednego WODu. Zawiera **snapshot** opisu — niezmienny nawet po edycji planu.

```swift
public struct WorkoutSessionResult: Equatable, Codable, Sendable {
    public var name: String         // "WOD 1" lub nazwa WODu
    public var description: String  // snapshot: "21-15-9 Thrusters 43kg + Pull-ups"
    public var score: String        // wpisany przez usera: "14:32", "12+5 rnd", "80kg"
    public var note: String         // opcjonalna notatka
}
```

**Dlaczego snapshot `description`:** 40kg ≠ 80kg. Historia musi odzwierciedlać to co faktycznie było wykonywane.

---

## Storage — plik JSON (stub)

Pierwsza implementacja: JSON → `Application Support/workoutPlanScores.json`.
Interfejs klienta identyczny z docelowym → swap na CoreData bez zmian w reducerach.

```swift
// TODO: IOS-00070-B2 — zastąpić CoreData + CloudKit
```

### Docelowo: CoreData + CloudKit

```
WorkoutPlanScoreEntity
├── id: UUID              (indexed, unique)
├── date: Date            (indexed — sortowanie)
├── trainingSessionId: UUID   (indexed — fetch by plan)
├── hkWorkoutId: UUID         (indexed ← KLUCZOWY — fetch by HK workout)
└── results: Data         (Transformable — [WorkoutSessionResult] jako JSON)
```

---

## WorkoutPlanScoreClient

```swift
struct WorkoutPlanScoreClient: Sendable {
    var save: @Sendable (WorkoutPlanScore) async throws -> Void
    var fetchByTrainingSessionId: @Sendable (UUID) async throws -> [WorkoutPlanScore]
    var fetchByHKWorkoutId: @Sendable (UUID) async throws -> WorkoutPlanScore?
}
```

---

## Jak powstaje WorkoutPlanScore

```
PlanDetailView
  → "Rozpocznij trening"
      │  trainingSession przekazany do SessionFeature
      ↓
LiveSession (trening trwa...)
      ↓
Workout kończy się → HKWorkout zapisany → hkWorkoutId = workout.uuid
      ↓
SummaryView
  → lista WODów z trainingSession.workouts
  → snapshot description z WorkoutSessionNew (ćwiczenia + wagi)
  → user wpisuje score per WOD
  → "Zapisz wyniki"
      ↓
WorkoutPlanScore(
    id:                UUID()
    date:              Date()
    trainingSessionId: trainingSession.id
    hkWorkoutId:       hkWorkoutId
    results: [
        WorkoutSessionResult(
            name:        "WOD 1",
            description: "21-15-9 Thrusters 43kg...",  ← snapshot
            score:       "14:32",                       ← wpisany
            note:        ""
        )
    ]
)
      ↓
workoutPlanScoreClient.save()
```

---

## FURTKI NA PRZYSZŁOŚĆ

- **Live session panel** — `WorkoutPhase` + `SessionPanel` → fazy planu widoczne podczas sesji
- **Progress charts** — `fetchByTrainingSessionId` → wykres poprawy score w czasie
- **PR detection** — parsing `score` (np. "14:32" < "13:55") → oznaczanie rekordów osobistych
- **CoreData → CloudKit** — swap `NSPersistentContainer` → `NSPersistentCloudKitContainer`
- **Edycja wyników po fakcie** — `save()` z istniejącym `id` → upsert

---

## SUBTASKI

### IOS-00070-A: Modele danych (SharedModels) ✅

Pliki:
- `SharedModels/PlannedSession/WorkoutPlanScore.swift` ✅
- `SharedModels/PlannedSession/WorkoutSessionResult.swift` ✅

---

### IOS-00070-B: WorkoutPlanScoreClient

**Plik:** `WorkoutMirrorLive/FeaturesNew/WorkoutTab/Session/Client/WorkoutPlanScoreClient.swift`

**liveValue (stub):** JSON → `Application Support/workoutPlanScores.json`
- `save` → load → upsert po `id` → zapis
- `fetchByTrainingSessionId` → load → filter → sort date desc
- `fetchByHKWorkoutId` → load → first match

**testValue:** `unimplemented()`

---

### IOS-00070-C: SummaryFeature — wyniki WODów + zapis

**Stan edytowalny per WOD (lokalny w SummaryFeature):**
```swift
struct WorkoutSessionResultInput: Identifiable, Equatable {
    var id: String           // "workout-0", "workout-1"
    var name: String         // "WOD 1"
    var description: String  // snapshot z planu
    var score: String = ""
    var note: String = ""
}
```

**Kluczowe zmiany:**
- `trainingSession: TrainingSession?` w State
- `resultInputs: IdentifiedArrayOf<WorkoutSessionResultInput>` — init z `trainingSession.workouts`
- `@Dependency(\.workoutPlanScoreClient)` w reducerze
- Akcja `saveResultsTapped` → buduje `WorkoutPlanScore` → `client.save()`

---

### IOS-00070-D: PlanDetailFeature — punkt wejścia + historia

**Destination:** `.session(SessionFeature)` ← `startWorkoutTapped`

**Historia:** `workoutPlanScoreClient.fetchByTrainingSessionId(id)` → lista kart z datą + wynikami WODów

`PlanDetailView`:
- Przycisk "Rozpocznij trening" (teal, `play.fill`) → `.fullScreenCover`
- Sekcja "Historia treningów" — karty z datą, WODy + score
- `.onAppear` → fetch historii

---

### IOS-00070-E: PersonalActivity — badge + szczegóły

`PersonalActivityView` — badge przy treningu z planem:
```swift
// fetchByHKWorkoutId(workout.uuid) → jeśli istnieje → badge z nazwą planu
```

`ActivityDetailsView` — sekcja z wynikami:
```swift
// Przy otwarciu: fetchByHKWorkoutId(workout.uuid) → WorkoutPlanScore?
// Sekcja z wynikami per WOD (name + description + score + note)
```

---

### [FURTKA] IOS-00070-F: Live session panel

Do implementacji gdy będziemy robić live session UX:
- `WorkoutPhase` enum + `TrainingSession.phases` / `wodPhases`
- `SessionPanel` enum
- `LiveSessionFeature` — phase timer (countdown / stopwatch)
- `LiveSessionView` — `PlannedPhasePanelView`

---

## Kolejność implementacji

```
IOS-00070-A (modele) ✅
    ↓
IOS-00070-B (WorkoutPlanScoreClient — stub JSON)
    ↓
IOS-00070-C (SummaryFeature — wpisanie wyników + zapis)
    ↓
IOS-00070-D (PlanDetailFeature — start + historia)
    ↓
IOS-00070-E (PersonalActivity — badge + szczegóły)
    ↓
[FURTKA] IOS-00070-F (Live session panel)
```

---

## Weryfikacja end-to-end

- [ ] PlanDetail → "Rozpocznij trening" → fullscreen sesja
- [ ] SummaryView: pokazuje tylko WODy (nie warmup/cooldown)
- [ ] SummaryView: description = snapshot z planu (ćwiczenia + wagi)
- [ ] "Zapisz wyniki" → `WorkoutPlanScore` zapisany w pliku JSON
- [ ] PlanDetailView: historia wykonań z wynikami
- [ ] PersonalActivity: badge przy treningach z planem
- [ ] ActivityDetailsView: sekcja z wynikami WODów
- [ ] Zmiana planu (ciężar) → stare wyniki nadal pokazują stary snapshot
- [ ] HKWorkout usunięty → `WorkoutPlanScore` nadal istnieje (własna `date`)
