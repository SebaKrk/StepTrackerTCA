# IOS-00072: Persystencja planów treningowych i wyników sesji (SQLiteData)

## Kontekst

W IOS-00070 powstały modele domenowe (`TrainingSession`, `WorkoutPlanScore`, `WorkoutSessionResult`) i tymczasowy klient JSON (`WorkoutPlanScoreClient`). Plany treningowe żyją wyłącznie w RAM (`@Shared(.inMemory)`) — po restarcie aplikacji znikają. Po zakończeniu treningu wyniki WOD-ów (`resultInputs`) w `SummaryFeature` nie są nigdzie zapisywane.

W IOS-00071 powstała infrastruktura `AppDatabase` (SQLiteData + CloudKitSyncable) z pierwszym rekordem `UserProfileRecord`.

Celem IOS-00072 jest:
1. Zapis planów treningowych (`TrainingSession`) do SQLite
2. Zapis wyniku sesji (`WorkoutPlanScore`) do SQLite po zakończeniu treningu
3. Odczyt obu typów danych z SQLite (listy, szczegóły, historia)
4. Zastąpienie tymczasowego JSON storage w `WorkoutPlanScoreClient` przez SQLiteData

---

## Architektura

```
SharedModels         → TrainingSession, WorkoutPlanScore, WorkoutSessionResult (bez zmian)
AppDatabase          → TrainingSessionRecord, WorkoutPlanScoreRecord + migracje
WorkoutMirrorLive    → TrainingSessionClient, WorkoutPlanScoreClient (SQLite)
                       PlansFeature (load/save z SQLite)
                       SummaryFeature (zapis WorkoutPlanScore przy "End Workout")
```

### Strategia serializacji zagnieżdżonych struktur

`TrainingSession` zawiera złożone pola (`warmUp`, `workouts`, `coolDown`, `exercises`). Zamiast wielu tabel z joinami — **podejście hybrydowe**:
- Kolumny skalarne (id, date, title, activity, location) → flat TEXT/INTEGER
- Pola zagnieżdżone → **BLOB (JSON encoded via Codable)**

Analogicznie `WorkoutPlanScore.results: [WorkoutSessionResult]` → BLOB.

Dzięki temu rekordy pozostają proste, a Codable modeli jest już w SharedModels.

---

## Subtaski

### KROK 1 — Records w AppDatabase

**Plik:** `AppDatabase/Sources/AppDatabase/Records/TrainingSessionRecord.swift`

```swift
@Table
public struct TrainingSessionRecord: Identifiable, CloudKitSyncable {
    public var id: UUID
    public var date: Date
    public var title: String
    public var activity: String          // rawValue WorkoutActivityType
    public var location: String          // rawValue WorkoutLocationType
    public var warmUpData: Data?         // JSON encoded WarmUpSession?
    public var workoutsData: Data        // JSON encoded [WorkoutSessionNew]
    public var coolDownData: Data?       // JSON encoded CoolDownSession?
    public var createdAt: Date
    public var updatedAt: Date
    public var ckRecordData: Data?
}

extension TrainingSessionRecord {
    public init(from session: TrainingSession, createdAt: Date, updatedAt: Date) throws { ... }
    public func toDomain() throws -> TrainingSession { ... }
}
```

**Plik:** `AppDatabase/Sources/AppDatabase/Records/WorkoutPlanScoreRecord.swift`

```swift
@Table
public struct WorkoutPlanScoreRecord: Identifiable, CloudKitSyncable {
    public var id: UUID
    public var date: Date
    public var trainingSessionId: UUID
    public var hkWorkoutId: UUID
    public var resultsData: Data         // JSON encoded [WorkoutSessionResult]
    public var createdAt: Date
    public var updatedAt: Date
    public var ckRecordData: Data?
}

extension WorkoutPlanScoreRecord {
    public init(from score: WorkoutPlanScore, createdAt: Date, updatedAt: Date) throws { ... }
    public func toDomain() throws -> WorkoutPlanScore { ... }
}
```

---

### KROK 2 — Migracje w Schema.swift

```swift
migrator.registerMigration("v3_trainingSession") { db in
    try #sql("""
        CREATE TABLE "trainingSessionRecords" (
          "id"           TEXT NOT NULL PRIMARY KEY ON CONFLICT REPLACE,
          "date"         TEXT NOT NULL,
          "title"        TEXT NOT NULL DEFAULT '',
          "activity"     TEXT NOT NULL DEFAULT '',
          "location"     TEXT NOT NULL DEFAULT '',
          "warmUpData"   BLOB,
          "workoutsData" BLOB NOT NULL,
          "coolDownData" BLOB,
          "createdAt"    TEXT NOT NULL,
          "updatedAt"    TEXT NOT NULL,
          "ckRecordData" BLOB
        ) STRICT
        """).execute(db)
}

migrator.registerMigration("v4_workoutPlanScore") { db in
    try #sql("""
        CREATE TABLE "workoutPlanScoreRecords" (
          "id"                TEXT NOT NULL PRIMARY KEY ON CONFLICT REPLACE,
          "date"              TEXT NOT NULL,
          "trainingSessionId" TEXT NOT NULL,
          "hkWorkoutId"       TEXT NOT NULL,
          "resultsData"       BLOB NOT NULL,
          "createdAt"         TEXT NOT NULL,
          "updatedAt"         TEXT NOT NULL,
          "ckRecordData"      BLOB
        ) STRICT
        """).execute(db)
    try #sql("""
        CREATE INDEX "index_workoutPlanScoreRecords_on_trainingSessionId"
        ON "workoutPlanScoreRecords"("trainingSessionId")
        """).execute(db)
}
```

---

### KROK 3 — TrainingSessionClient

**Plik:** `WorkoutMirrorLive/FeaturesNew/ActivitiesTab/.../Plans/Client/TrainingSessionClient.swift`

```swift
struct TrainingSessionClient: Sendable {
    var save:     @Sendable (TrainingSession) async throws -> Void
    var fetchAll: @Sendable () async throws -> [TrainingSession]
    var delete:   @Sendable (UUID) async throws -> Void
}
```

`liveValue`: `@Dependency(\.defaultDatabase)` → `write`/`read` na `TrainingSessionRecord`

---

### KROK 4 — WorkoutPlanScoreClient — zastąpienie JSON przez SQLite

**Plik:** `WorkoutMirrorLive/.../Session/Client/WorkoutPlanScoreClient.swift`

Istniejący interfejs bez zmian:
```swift
struct WorkoutPlanScoreClient: Sendable {
    var save:                    @Sendable (WorkoutPlanScore) async throws -> Void
    var fetchByTrainingSessionId: @Sendable (UUID) async throws -> [WorkoutPlanScore]
    var fetchByHKWorkoutId:       @Sendable (UUID) async throws -> WorkoutPlanScore?
}
```

Zmiana: `liveValue` — usuń `WorkoutPlanScoreStore` (JSON actor), zastąp reads/writes na `WorkoutPlanScoreRecord` przez `@Dependency(\.defaultDatabase)`.

---

### KROK 5 — PlansFeature — load/save z SQLite

**Pliki do modyfikacji:**
- `PlansFeature+State.swift` — usuń `@Shared(.inMemory("plannedWorkouts"))`, dodaj `var sessions: [TrainingSession] = []`
- `PlansFeature+Action.swift` — dodaj `fetchSessions`, `sessionsLoaded([TrainingSession])`, `deleteSession(UUID)`
- `PlansFeature.swift` — `@Dependency(\.trainingSessionClient)`:
  - `viewDidAppear` → `fetchSessions`
  - `.delegate(.saved(session))` z AddPlanFeature → `client.save(session)` + `fetchSessions`
  - `deleteSession` → `client.delete(id)` + usuń z state

---

### KROK 6 — SummaryFeature — zapis WorkoutPlanScore przy "End Workout"

**Plik:** `WorkoutMirrorLive/.../Session/Child/Summary/Feature/SummaryFeature.swift`

Dodaj `@Dependency(\.workoutPlanScoreClient)`.

Przy `.view(.endWorkoutButtonTapped)` — gdy `trainingSession != nil` i `summary?.workout?.uuid != nil`:

```swift
let score = WorkoutPlanScore(
    trainingSessionId: trainingSession.id,
    hkWorkoutId: summary.workout.uuid,
    results: state.resultInputs
)
try await workoutPlanScoreClient.save(score)
await dismiss()
```

Gdy brak planu — samo `dismiss()` jak dotychczas.

---

## Kolejność implementacji

```
KROK 1 → TrainingSessionRecord + WorkoutPlanScoreRecord (AppDatabase)
KROK 2 → Migracje v3 + v4 (Schema.swift)
KROK 3 → TrainingSessionClient
KROK 4 → WorkoutPlanScoreClient (zastąpienie JSON → SQLite)
KROK 5 → PlansFeature (load/save)
KROK 6 → SummaryFeature (zapis przy End Workout)
```

---

## Pliki krytyczne

| Plik | Akcja |
|------|-------|
| `AppDatabase/Sources/AppDatabase/Records/TrainingSessionRecord.swift` | NOWY |
| `AppDatabase/Sources/AppDatabase/Records/WorkoutPlanScoreRecord.swift` | NOWY |
| `AppDatabase/Sources/AppDatabase/Schema.swift` | MODYFIKACJA (v3, v4) |
| `.../Plans/Client/TrainingSessionClient.swift` | NOWY |
| `.../Session/Client/WorkoutPlanScoreClient.swift` | MODYFIKACJA (JSON → SQLite) |
| `.../Plans/Feature/PlansFeature+State.swift` | MODYFIKACJA |
| `.../Plans/Feature/PlansFeature+Action.swift` | MODYFIKACJA |
| `.../Plans/Feature/PlansFeature.swift` | MODYFIKACJA |
| `.../Session/Child/Summary/Feature/SummaryFeature.swift` | MODYFIKACJA |

**Modele referencyjne (wzorce do naśladowania):**
- `AppDatabase/Sources/AppDatabase/Records/UserProfileRecord.swift` — wzorzec Record
- `AppDatabase/Sources/AppDatabase/Schema.swift` — wzorzec migracji
- `.../PersonSettings/Client/UserProfileClient.swift` — wzorzec Client

---

## Weryfikacja end-to-end

- [ ] App startuje bez crashu po dodaniu migracji v3 i v4
- [ ] Tworzę plan → wychodzę z app → wracam → plan nadal widoczny
- [ ] Usuwam plan → znika z listy i z bazy
- [ ] Kończę trening z planem → "End Workout" → `WorkoutPlanScore` zapisany
- [ ] Wchodzę do PlanDetail → historia wykonań widoczna
- [ ] Kill + restart → historia nadal dostępna
