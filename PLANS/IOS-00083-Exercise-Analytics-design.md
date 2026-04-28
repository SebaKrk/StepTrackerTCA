# IOS-00083 — Exercise Analytics

## Overview

Per-exercise tracking, analytics and comparison across workouts. Replaces WOD-level scoring with exercise-level granularity + HR per phase from Watch.

**Kontekst CrossFit:** Plany treningowe rzadko się powtarzają. Porównywanie całych sesji jest bezwartościowe. Wartościowe jest porównywanie **konkretnego ćwiczenia** (np. Thrusters) na przestrzeni wielu różnych treningów — niezależnie od tego w jakim WOD wystąpiło.

**Killer feature:** Dane HR z Apple Watch powiązane z konkretnym ćwiczeniem. Żadna inna apka CrossFit (BTWB, SugarWOD, WODBoard) tego nie ma. Jeśli robisz Thrusters 43kg i 3 tygodnie temu avg HR był 170 a teraz 158 → ciało się adaptuje → czas podbić wagę.

## Problem

- Wyniki są na poziomie WOD (`score: String`), nie ćwiczenia
- Plany się nie powtarzają → porównywanie sesji bezwartościowe
- Brak śledzenia progresji per ćwiczenie (waga, volume, reps)
- HR dane istnieją ale nie są powiązane z fazami/ćwiczeniami
- `ExerciseType` enum + `customName: String` — brak ustandaryzowanego matchingu (literówki, skróty, synonimy → osobne wpisy w bazie)

## Solution

1. Katalog ćwiczeń z aliasami → deterministyczny matching
2. `ExerciseLog` — nowa tabela SQL per-exercise
3. Typowane score WOD (`WodScoreResult` enum zamiast `String`)
4. Summary screen z per-exercise input (pre-fill z planu + płeć)
5. Analytics view — balance chart + lista + drilldown per ćwiczenie
6. HR bufor + phase tracking → per-phase HR w `ExerciseLog`

---

## Decyzje architektoniczne (podjęte w brainstormingu)

| Decyzja | Wybór | Dlaczego |
|---|---|---|
| Lokalizacja katalogu | SharedModels (obok ExerciseType) | Najprostsze, później wydzielenie do SDK |
| Remote catalog | Nie teraz | Zbuduj lokalnie, zwaliduj, wydziel później |
| ExerciseKit SDK | Przyszłość | Interfejs gotowy do wydzielenia (ExerciseCatalogClient) |
| Backward compatibility | Nie potrzebna | App nie jest wydana |
| AI matching | AI rozpoznaje sam, apka waliduje lokalnie | Oszczędność tokenów, aliases jako wsparcie dla przyszłych lokalnych modeli |
| Unmatched exercises | Zapisz jako unmatchedName: String | Auto-migracja gdy dodane do katalogu |
| GitHub Issues (unmatched) | Przyszłość (SDK) | Na teraz — log |
| equipment / isBodyweight | Wyrzucone | YAGNI |
| Kategorie ruchów | CrossFit-specific (nie push/pull/squat/hinge) | Strength, Olympic, Gymnastics, Cardio, Mixed |
| User input na Summary | Zero friction: pre-fill → edit opcjonalny | CrossFit ludzie po WOD są zmęczeni |
| Waga pre-fill | Auto z planu + płeć (M/F) z HealthKit | Eliminuje ręczne wpisywanie |
| Okno edycji | 12h po zakończeniu | Można poprawić, ale nie w nieskończoność |
| Phase tracking | Implementujemy od razu | Mamy PhasePanelFeature + HR stream, brakuje tylko bufor |
| Phase undo/go back | Przyszłość | V1 bez problemów, dopracujemy później |
| Coaching insights | Przyszłość | Na start — czyste dane i wykresy |

---

## Sekcja 1: ExerciseDefinition (katalog ćwiczeń)

**Location:** SharedModels (obok istniejącego `ExerciseType`)

### Model

```swift
struct ExerciseDefinition: Sendable {
    let type: ExerciseType         // .thrusters — klucz SQL, rawValue = nazwa w UI
    let aliases: [String]          // ["T2B", "TTB", "Toes2Bar"] — matching
    let category: MovementCategory // .gymnastics — wykres balance
}

enum MovementCategory: String, Codable, Sendable {
    case strength       // Deadlift, Back Squat, Bench Press, Strict Press
    case olympicLifting // Clean & Jerk, Snatch, Thruster, Power Clean
    case gymnastics     // Pull-ups, HSPU, Muscle-ups, T2B, Pistols, Ring Dips
    case cardio         // Row, Bike, Run, Ski Erg, Jump Rope, Double Unders
    case mixed          // Burpees, Wall Balls, Devil Press, Man Maker
}
```

### Rola poszczególnych pól

- **`type: ExerciseType`** — unikalny identyfikator. Enum który już istnieje w SharedModels. `rawValue` = oficjalna nazwa wyświetlana w UI (np. "Thrusters"). Klucz do SQL: `WHERE exerciseType = .thrusters`.

- **`aliases: [String]`** — alternatywne nazwy tego samego ćwiczenia. Służą do matchingu po skanowaniu OCR. Przykłady:
  - Skróty: "T2B", "HSPU", "C&J", "DU"
  - Singular/plural: "Thruster" vs "Thrusters"
  - Z/bez myślnika: "Clean and Jerk" vs "Clean & Jerk"
  - Warianty: "Squat to Press" (= Thruster)
  - Przyszłość: wsparcie dla lokalnych modeli AI (Apple Foundation Models) które mogą nie znać wszystkich nazw

- **`category: MovementCategory`** — typ ruchu w kontekście CrossFit. Służy do wykresu "Movement Balance" — czy trenujesz równomiernie. Kategorie dopasowane do tego jak CrossFit box organizuje trening ("dziś mamy Olympic + Gymnastics WOD").

### Statyczny katalog

Na start — array w kodzie:

```swift
let exerciseCatalog: [ExerciseDefinition] = [
    ExerciseDefinition(
        type: .thrusters,
        aliases: ["Thruster", "Squat Thruster"],
        category: .olympicLifting
    ),
    ExerciseDefinition(
        type: .toesToBar,
        aliases: ["T2B", "TTB", "Toes2Bar", "Toes to Bar"],
        category: .gymnastics
    ),
    ExerciseDefinition(
        type: .cleanAndJerk,
        aliases: ["C&J", "Clean & Jerk", "Clean and Jerk", "CJ"],
        category: .olympicLifting
    ),
    // ... reszta ćwiczeń
]
```

**Przyszłość:** Wydzielenie do ExerciseKit Swift Package + remote JSON (np. GitHub Pages). Apka pobiera przy starcie, cachuje lokalnie. Update katalogu bez wydawania nowej wersji apki.

---

## Sekcja 2: Matching (AI → katalog → ExerciseLog)

### Pełny flow od tablicy do SQL

```
Tablica w CrossFit box:
  "FOR TIME: 21-15-9
   Thrusters 43/30kg
   Burpees
   T2B"
       ↓
1. OCR + Claude API
       ↓
   ExtractedExercise:
     name: "Thrusters", reps: "21-15-9", weight: "43/30"
     name: "Burpees",   reps: "21-15-9"
     name: "T2B",       reps: "21-15-9"
       ↓
2. Matching (na iPhone, lokalnie — oszczędność tokenów)
       ↓
   Dla każdego name:
     a) exact:  name.lowercased() == ExerciseType.rawValue.lowercased()
                "Burpees" == "Burpees" ✅
     b) alias:  name ∈ definition.aliases (case-insensitive)
                "T2B" ∈ toesToBar.aliases ✅
     c) fuzzy:  prefix match
                "Thruster" hasPrefix "Thrusters" ✅
     d) fail:   unmatchedName = "Devil Press" ❌ → log
       ↓
3. Budowanie ExerciseSession (plan treningowy)
       ↓
   exerciseType: .thrusters, target: .reps("21-15-9"), weight: 43.0
   exerciseType: .burpees,   target: .reps("21-15-9"), weight: nil
   exerciseType: .toesToBar, target: .reps("21-15-9"), weight: nil
       ↓
4. User robi trening (Watch zbiera HR)
       ↓
5. Summary Screen → pre-fill z planu
     Waga: WeightConfiguration(men: 43, women: 30)
           + biologicalSex z HealthKit
           → M = 43kg, F = 30kg (automatycznie)
     Reps: z planu (21-15-9)
     Scaling: Rx (domyślne)
       ↓
6. User klika "Zapisz" (lub nie dotyka niczego — pre-fill wystarczy)
       ↓
7. ExerciseLog rows do SQL (jeden per ćwiczenie)
```

### Matching implementation

```swift
func match(_ name: String) -> ExerciseType? {
    let normalized = name
        .trimmingCharacters(in: .whitespaces)
        .lowercased()

    // 1. Exact match po rawValue
    if let type = ExerciseType(rawValue: normalized) {
        return type
    }

    // 2. Alias match
    for definition in exerciseCatalog {
        let aliases = definition.aliases.map { $0.lowercased() }
        if aliases.contains(normalized) {
            return definition.type
        }
    }

    // 3. Fuzzy — singular/plural
    for definition in exerciseCatalog {
        let raw = definition.type.rawValue.lowercased()
        if raw.hasPrefix(normalized) || normalized.hasPrefix(raw) {
            return definition.type
        }
    }

    // 4. Nie znaleziono
    return nil
}
```

Prosty, deterministyczny, bez ML. Na start wystarczy. Rozbudowa fuzzy w przyszłości jeśli potrzeba.

### Co się dzieje z unmatched?

```
match("Devil Press") → nil
       ↓
ExerciseLog:
  exerciseType: nil
  unmatchedName: "Devil Press"
  category: nil
       ↓
Przyszłość (po wydzieleniu SDK):
  → auto GitHub Issue: "Unknown exercise: Devil Press"
  → Dev dodaje do katalogu
  → Apka sync → migracja:
    UPDATE exerciseLog
    SET exerciseType = 'devilPress', category = 'mixed'
    WHERE unmatchedName = 'Devil Press'
```

---

## Sekcja 3: ExerciseLog (tabela SQL)

**Nowa tabela w AppDatabase.** Jeden wiersz = jedno ćwiczenie z jednego WOD z jednego treningu.

Przykład: WOD miał 3 ćwiczenia (Thrusters, Burpees, T2B) → 3 wiersze w tabeli.

### Schema

```swift
@Table struct ExerciseLog {
    let id: UUID
    let date: Date

    // ── Identyfikacja ćwiczenia ──
    // Zawsze dokładnie jedno z dwóch jest wypełnione:
    let exerciseType: ExerciseType?   // znane → .thrusters (link do katalogu)
    let unmatchedName: String?        // nieznane → "Devil Press" (string)
    let category: MovementCategory?   // zduplikowane z katalogu — żeby SQL nie musiał joinować

    // ── Kontekst treningu ──
    let workoutPlanScoreId: UUID?     // → WorkoutPlanScore (nawigacja: wykres → trening)
    let wodName: String?              // "WOD 1" — w którym WOD było ćwiczenie

    // ── Plan (pre-fill z ExerciseSession) ──
    let plannedReps: String?          // "21-15-9"
    let plannedWeight: Double?        // 43.0 (po uwzględnieniu płci)

    // ── Actual (user input, domyślnie = planned) ──
    let actualWeight: Double?         // 43.0 — user zmienia jeśli skalował
    let actualReps: String?           // "21-15-9" — user zmienia jeśli nie dokończył
    let scaling: ScalingType          // .rx / .scaled / .rxPlus
    let isPR: Bool                    // user zaznacza ręcznie

    // ── HR per phase (automatyczne z Watch) ──
    let avgHeartRate: Double?         // avg HR w czasie tego WOD/fazy
    let maxHeartRate: Double?         // max HR w czasie tego WOD/fazy
    let phaseStartDate: Date?         // kiedy faza się zaczęła
    let phaseEndDate: Date?           // kiedy faza się skończyła
    let timeInPhase: TimeInterval?    // czas trwania fazy (sekundy)

    // ── Obliczone przy zapisie ──
    let volumeLoad: Double?           // totalReps × weight (np. 45 × 43 = 1935 kg)
    let tempoPerRound: Double?        // WOD score ÷ rounds (np. 872s ÷ 3 = 290s)

    let note: String?                 // opcjonalna notatka per ćwiczenie
    let editableUntil: Date?          // date + 12h → po tym readonly
}

enum ScalingType: String, Codable, Sendable {
    case rx, scaled, rxPlus
}
```

### Kluczowe relacje

```
ExerciseLog.exerciseType ──→ ExerciseDefinition.type (katalog)
ExerciseLog.workoutPlanScoreId ──→ WorkoutPlanScore.id (trening)
```

- `exerciseType` → grupowanie per ćwiczenie w analytics
- `workoutPlanScoreId` → klik na wykresie → nawigacja do treningu

### Przydatne SQL queries

```sql
-- Historia jednego ćwiczenia
SELECT * FROM exerciseLog
WHERE exerciseType = 'thrusters'
ORDER BY date DESC

-- Tygodniowy volume
SELECT strftime('%W', date) AS week, SUM(volumeLoad) AS total
FROM exerciseLog
WHERE exerciseType = 'thrusters'
GROUP BY week

-- PR per ćwiczenie
SELECT exerciseType, MAX(actualWeight) AS pr
FROM exerciseLog
WHERE actualWeight IS NOT NULL
GROUP BY exerciseType

-- Movement balance w miesiącu
SELECT category, COUNT(*) AS count
FROM exerciseLog
WHERE date >= '2026-04-01' AND date < '2026-05-01'
GROUP BY category

-- HR per phase vs per cały trening
-- Per phase: bezpośrednio z ExerciseLog row
-- Per trening:
SELECT AVG(avgHeartRate), MAX(maxHeartRate)
FROM exerciseLog
WHERE workoutPlanScoreId = ?
```

### tempoPerRound obliczenie

Zależy od typu WOD:
- `forTime`: `time / totalRounds` → "14:32 na 3 rundy = 290s/runda"
- `timeCap`: `nil` → nie dokończył, nie ma sensu liczyć
- `amrap`: `capTime / rounds` → "12min / 8 rounds = 90s/runda"
- reszta: `nil`

### 12h okno edycji

`editableUntil = date + 12h`. Po tym czasie ExerciseLog jest readonly. User może poprawić dane (np. "a jednak dałem 40kg nie 43") ale nie w nieskończoność.

---

## Sekcja 4: WodScoreResult (typowane score WOD)

### Problem

Obecny `WorkoutSessionResult.score: String` to luźny string ("14:32", "8+3", "120kg"). Nie da się z tego wyciągnąć danych do analytics. Nie da się obliczyć tempoPerRound bez parsowania stringa.

### Rozwiązanie

Zastąpienie `score: String` typowanym enumem. **Nie ma backward compatibility — app nie jest wydana.**

```swift
struct WorkoutSessionResult: Codable, Sendable, Equatable, Identifiable {
    var id: UUID = UUID()
    var name: String                    // "WOD 1"
    var description: String             // snapshot: "21-15-9 Thrusters 43kg"
    var scoreResult: WodScoreResult     // typowane score
    var note: String                    // notatka per WOD
    var exercises: [ExerciseLogInput]   // per-exercise input z Summary
}

enum WodScoreResult: Codable, Sendable, Equatable {
    case forTime(time: TimeInterval)                    // skończony w czasie
    case timeCap(capSeconds: Int, remainingReps: Int)   // nie skończony, ile brakuje
    case amrap(rounds: Int, extraReps: Int)             // X rund + Y reps
    case forLoad(weight: Double)                        // 1RM, max weight
    case forReps(reps: Int)                             // max reps/cals
    case completed                                       // EMOM completed, itp.
    case custom(String)                                  // furtka na nietypowe formaty
}

extension WodScoreResult {
    var displayString: String {
        switch self {
        case .forTime(let t):              return t.formattedDuration()
        case .timeCap(let cap, let reps):  return "TC \(cap/60)' + \(reps) reps"
        case .amrap(let r, let extra):     return "\(r) rds + \(extra) reps"
        case .forLoad(let w):              return "\(Int(w)) kg"
        case .forReps(let r):              return "\(r) reps"
        case .completed:                   return "✓"
        case .custom(let s):               return s
        }
    }
}
```

### UI per typ WOD na Summary Screen

```
FOR TIME (skończony):
  Status: [✅ Completed]
  Time:   [14:32]

FOR TIME (time cap, nie skończył):
  Status: [⏱ Time Cap]
  Remaining: [45 reps]

AMRAP:
  Rounds: [8]  + Reps: [3]

FOR LOAD (1RM):
  Weight: [120] kg

EMOM / inne:
  [✓ Completed]

Custom:
  [wolny tekst]
```

---

## Sekcja 5: Summary Screen (UI per-exercise input)

### Zasady UX

1. **Zero friction domyślnie** — wszystkie pola pre-fill z planu. Waga auto z płci (M/F). Scaling = Rx. User nie musi dotknąć niczego.
2. **Edycja opcjonalna** — tap zmienia actual reps/weight. Scaling dropdown. PR checkbox. Ale nie wymuszane.
3. **HR per phase automatyczne** — obliczone z hrBuffer × phase timestamps. Zero inputu od usera.
4. **12h okno edycji** — po zapisie user może wrócić i poprawić. Po 12h → readonly.

### Layout

```
┌─────────────────────────────────────┐
│  Summary                            │
├─────────────────────────────────────┤
│  Boks · 14:32 · 24 kwi             │
│  🔥 520 kcal   ♥ 165 avg   178 max │
├─────────────────────────────────────┤
│                                     │
│  WOD 1 · FOR TIME                   │
│  Score: [14:32]                     │
│  ♥ avg 162 / max 174 · 14:32       │
│                                     │
│  ┌─ Exercises ──────────────────┐   │
│  │                              │   │
│  │  Thrusters              43kg │   │
│  │  Plan: 21-15-9               │   │
│  │  Actual: [21-15-9] [43]kg    │   │
│  │  [Rx ▼]              [ ] PR  │   │
│  │  ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─   │   │
│  │  Burpees                  BW │   │
│  │  Plan: 21-15-9               │   │
│  │  Actual: [21-15-9]           │   │
│  │  [Rx ▼]              [ ] PR  │   │
│  │  ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─   │   │
│  │  Toes to Bar              BW │   │
│  │  Plan: 21-15-9               │   │
│  │  Actual: [21-15-9]           │   │
│  │  [Rx ▼]              [ ] PR  │   │
│  │                              │   │
│  └──────────────────────────────┘   │
│                                     │
│  WOD 2 · AMRAP 12min               │
│  Rounds: [8]  + Reps: [3]          │
│  ♥ avg 170 / max 182 · 12:00       │
│                                     │
│  ┌─ Exercises ──────────────────┐   │
│  │  Pull-ups                 BW │   │
│  │  Plan: 7 reps                │   │
│  │  Actual: [7]                 │   │
│  │  [Rx ▼]              [ ] PR  │   │
│  │  ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─   │   │
│  │  Sit-Ups                  BW │   │
│  │  Plan: 15 reps               │   │
│  │  Actual: [15]                │   │
│  │  [Rx ▼]              [ ] PR  │   │
│  │  ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─   │   │
│  │  Double Unders            BW │   │
│  │  Plan: 25 reps               │   │
│  │  Actual: [25]                │   │
│  │  [Rx ▼]              [ ] PR  │   │
│  └──────────────────────────────┘   │
│                                     │
├─────────────────────────────────────┤
│  [Odrzuć]                 [Zapisz]  │
└─────────────────────────────────────┘
```

### Flow zapisu

```
User klika "Zapisz"
       ↓
1. WorkoutPlanScore (istniejący) — score per WOD (jak dotychczas)
       ↓
2. ExerciseLog rows (nowe) — per ćwiczenie:
   - exerciseType z matchingu
   - planned* z ExerciseSession planu
   - actual* z user input (lub = planned jeśli nie dotknął)
   - HR z hrBuffer × phaseTimestamps
   - volumeLoad obliczony
   - tempoPerRound obliczony z WodScoreResult
   - editableUntil = now + 12h
       ↓
3. dismiss()
```

---

## Sekcja 6: Analytics View

### Główny widok (jeden scrollowalny ekran)

```
┌─────────────────────────────────────┐
│  Exercise Analytics                 │
├─────────────────────────────────────┤
│                                     │
│  [Month ◀ April 2026 ▶]            │
│                                     │
│  MOVEMENT BALANCE                   │
│  ┌──────────────────────────────┐   │
│  │   ██     ██            ████  │   │
│  │   ██     ██     ██     ████  │   │
│  │   ████   ████   ████   ████  │   │
│  │   ████   ████   ██████ ████  │   │
│  └──────────────────────────────┘   │
│   W1     W2     W3     W4          │
│                                     │
│  ■ Strength 25%                     │
│  ■ Olympic 30%                      │
│  ■ Gymnastics 28%                   │
│  ■ Cardio 12%                       │
│  ■ Mixed 5%                         │
│                                     │
│  ─────────────────────────────────  │
│                                     │
│  ALL EXERCISES · 23                 │
│  [Frequency ▼] [Weight] [Volume]   │
│                                     │
│  🏋️ Thrusters              18×    │
│     43kg · Olympic       PR 45kg ›  │
│  ─────────────────────────────────  │
│  💪 Pull-ups                14×    │
│     BW · Gymnastics      ↑+3 mar ›  │
│  ─────────────────────────────────  │
│  🔥 Burpees                 12×    │
│     BW · Mixed                   ›  │
│  ─────────────────────────────────  │
│  🏋️ Clean & Jerk            9×    │
│     60kg · Olympic       PR 70kg ›  │
│  ─────────────────────────────────  │
│  🦵 Wall Balls               9×    │
│     9kg · Mixed                  ›  │
│  ─────────────────────────────────  │
│  ⚡ Deadlift                 6×    │
│     100kg · Strength     PR 120kg ›  │
│  ─────────────────────────────────  │
│       ... reszta listy ...          │
└─────────────────────────────────────┘
```

### Sortowanie listy

- **Frequency** — ile razy ćwiczenie wystąpiło w miesiącu (domyślne)
- **Weight** — posortowane po max actualWeight (bodyweight na dole)
- **Volume** — posortowane po łącznym volumeLoad

### Exercise drilldown (tap na ćwiczenie)

```
┌─────────────────────────────────────┐
│  ‹ Back         Thrusters      🔋   │
├─────────────────────────────────────┤
│  Olympic Lifting                    │
│                                     │
│  PR: 45 kg          18× w kwietniu  │
│  Avg HR: 162        Max HR: 178     │
├─────────────────────────────────────┤
│                                     │
│  WEIGHT PROGRESSION                 │
│  ┌──────────────────────────────┐   │
│  │ 45 ┤                  ●━● PR │   │
│  │ 43 ┤      ●━●━●━●━●━●       │   │
│  │ 40 ┤ ●━●━●                   │   │
│  └──┬──┬──┬──┬──┬──┬──┬──┬──┘  │   │
│    1/4       15/4       24/4        │
│                                     │
│  VOLUME PER WEEK                    │
│  ┌──────────────────────────────┐   │
│  │  ████                        │   │
│  │  ████  ████         ████     │   │
│  │  ████  ████  ████   ████     │   │
│  └──┬─────┬─────┬─────┬────┘   │   │
│    W1    W2    W3    W4             │
│                                     │
│  AVG HR PER SESSION                 │
│  ┌──────────────────────────────┐   │
│  │ 170 ┤      ●                 │   │
│  │ 165 ┤ ●         ●     ●     │   │
│  │ 158 ┤                     ●  │   │
│  └──┬──┬──┬──┬──┬──┬──┬──┬──┘  │   │
│    1/4       15/4       24/4        │
│  (HR spada przy tej samej wadze     │
│   = adaptacja → czas podbić wagę)  │
│                                     │
├─────────────────────────────────────┤
│  HISTORY                            │
│                                     │
│  24 kwi · WOD 1 · FOR TIME         │
│  43kg · 21-15-9 · Rx                │
│  Score: 14:32  ♥ 165/174     ›     │
│  ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─   │
│  20 kwi · WOD 3 · AMRAP            │
│  40kg · 15-12-9 · Scaled            │
│  Score: 8+3   ♥ 158/170      ›     │
│  ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─   │
│  15 kwi · WOD 1 · FOR TIME         │
│  43kg · 21-15-9 · Rx                │
│  Score: 15:01  ♥ 170/182     ›     │
│                                     │
│       tap → nawigacja do treningu   │
└─────────────────────────────────────┘
```

### 3 wykresy w drilldown

| Wykres | Dane z SQL | Wartość dla usera |
|---|---|---|
| Weight Progression | `actualWeight` per date | Czy idę w górę z ciężarem? |
| Volume per Week | `SUM(volumeLoad) GROUP BY week` | Ile łącznie podnoszę? |
| Avg HR per Session | `avgHeartRate` per date | HR spada = adaptacja = czas podbić wagę |

**HR wykres to killer feature** — unikalna wartość apki. Żadna apka CrossFit nie łączy HR z Watch z per-exercise tracking.

### Metryki per ćwiczenie bodyweight (Pull-ups, Burpees, T2B)

Ćwiczenia bez wagi — inne metryki:
- **Volume** — łączne reps (zamiast reps × weight)
- **Tempo per round** — score WOD ÷ rundy → trend poprawy
- **Scaling progression** — Scaled → Rx → Rx+ (widoczne w historii)
- **HR** — tak samo jak weighted exercises

---

## Sekcja 7: HR bufor + Phase Tracking

### Problem

Watch wysyła HR co ~5s. LiveSessionFeature wyświetla tylko ostatnią wartość (nadpisuje). Brak historii = brak per-phase HR.

### Rozwiązanie

#### 1. HR bufor w LiveSessionFeature.State

```swift
// LiveSessionFeature+State.swift
var hrBuffer: [(date: Date, bpm: Double)] = []
```

Append przy każdym `workoutMetrics`:

```swift
case let .workoutMetrics(data):
    let effectiveHR = data.heartRate > 0
        ? data.heartRate
        : state.workoutMetrics.heartRate

    if effectiveHR > 0 {
        state.hrBuffer.append((Date(), effectiveHR))
    }
    // ... reszta bez zmian
```

**Pamięć:** HR co 5s × 60 min = ~720 samples × 16 bytes = ~12 KB. Zero problemu.

#### 2. Phase timestamps w PhasePanelFeature

```swift
struct PhaseTimestamp: Equatable, Sendable {
    let phaseName: String       // "WOD 1"
    let startDate: Date
    var endDate: Date?
}

// W PhasePanelFeature.State:
var phaseTimestamps: [PhaseTimestamp] = []
```

- Start fazy: `append(PhaseTimestamp(phaseName: "WOD 1", startDate: Date()))`
- "Next phase": `timestamps[current].endDate = Date()` + append nowa
- Koniec treningu: `timestamps[last].endDate = Date()`
- **Minimum 5s** — ignoruj "next" jeśli faza trwa < 5 sekund (double-tap protection)

#### 3. Obliczenie per-phase HR przy zapisie

```swift
func calculatePhaseHR(
    hrBuffer: [(date: Date, bpm: Double)],
    phase: PhaseTimestamp
) -> (avg: Double, max: Double)? {

    guard let end = phase.endDate else { return nil }

    let samples = hrBuffer.filter {
        $0.date >= phase.startDate && $0.date <= end
    }

    guard !samples.isEmpty else { return nil }

    let avg = samples.map(\.bpm).reduce(0, +) / Double(samples.count)
    let max = samples.map(\.bpm).max() ?? 0

    return (avg, max)
}
```

#### 4. Pełny flow

```
Trening start
       ↓
Watch wysyła HR co ~5s
       ↓
LiveSessionFeature: hrBuffer.append((date, bpm))
       ↓
User klika "next phase" w PhasePanelFeature
       ↓
phaseTimestamps: [
    (WOD 1, start: 11:05:30, end: 11:20:02),
    (WOD 2, start: 11:20:02, end: 11:35:15)
]
       ↓
Trening end → Summary
       ↓
Zapis:
  WOD 1 exercises → filter hrBuffer[11:05:30...11:20:02]
    → Thrusters: avg 162, max 174
    → Burpees:   avg 162, max 174  (ten sam WOD = ten sam HR)
    → T2B:       avg 162, max 174

  WOD 2 exercises → filter hrBuffer[11:20:02...11:35:15]
    → Pull-ups:  avg 170, max 182
    → Sit-Ups:   avg 170, max 182
    → DU:        avg 170, max 182
```

#### 5. Fallback (brak faz)

Trening bez planu = brak PhasePanelFeature = `phaseTimestamps` pusty.
→ HR z całego `hrBuffer` jako fallback dla wszystkich ExerciseLog rows.

---

## Zmiany modelu (ustalone 2026-04-27)

### SetEntry — per-set input dla Strength

```swift
public struct SetEntry: Identifiable, Equatable, Codable, Sendable {
    public var id: UUID
    public var reps: Int
    public var weight: Double?
}
```

Dodany do `ExerciseLogInput.sets: [SetEntry]?` — `nil` dla WOD (prosty input), wypełniony dla Strength (per-set input).

### ExerciseTarget w ExerciseLogInput

`ExerciseLogInput.target: ExerciseTarget?` — przeniesiony z `ExerciseSession`. Pozwala UI wiedzieć jaką jednostkę wyświetlić (reps/cal/meters/etc.) bez hackowania na stringach.

### Rx/Scaled/PR usunięte z Summary input

Apka oblicza automatycznie:
- **PR:** porównanie `actualWeight` / `sets[].weight.max()` z historią w ExerciseLog SQL
- **Scaling:** porównanie `actualWeight` vs `plannedWeight` (actual < planned → scaled)

### Score WOD ukryty dla Strength

Gdy ćwiczenia w WOD mają `sets != nil` → score input jest ukryty. Max weight obliczany z serii.

### Summary UI — Set Input Sheet

Zamiast inline tabeli na Summary → przycisk "Log sets" otwiera sheet.

```
Przed uzupełnieniem:
  Bench Press
  Plan: 10-10-10-10-10
  [⊕ Log sets]

Sheet (SetInputFeature):
  ┌─ Bench Press ──── [Done] ─┐
  │ Set   Reps    kg           │
  │  1    [10]    [40]         │
  │  2    [10]    [45]         │
  │  3    [10]    [50]         │
  └────────────────────────────┘

Po zamknięciu (kompaktowy podgląd):
  Bench Press
  Plan: 10-10-10-10-10
  10×40 · 10×45 · 10×50 · 10×55 · 10×60
  [✏ Edit sets]
```

`SetInputFeature` — osobny TCA feature (State, Action, Reducer, View). Prezentowany jako `@Presents` Destination z SummaryFeature.

### Textual (markdown rendering)

`gonzalezreal/textual` — SPM dependency do renderowania markdown tabel w read-only widoku.
Flow: `[SetEntry]` → markdown string → Textual renderuje tabelę.

---

## Przyszłość (nie w tym zadaniu)

- **ExerciseKit** — osobny Swift Package z katalogiem, matchingiem, modelami
- **Remote catalog** — JSON na GitHub Pages, apka pobiera przy starcie, cachuje lokalnie
- **GitHub Issues** — automatyczne issue na repo SDK dla unmatched exercises
- **Auto-migracja** — `UPDATE exerciseLog SET exerciseType = ? WHERE unmatchedName = ?` po sync katalogu
- **Coaching insights** — reguły: "HR spada + waga ta sama = adaptacja", "Hinge < 15% = zaniedbane"
- **Phase undo** — cofnij ostatnią zmianę fazy
- **Per-exercise HR** — gdyby Watch znał granice ćwiczeń w ramach fazy (nie tylko per phase, ale per exercise)
- **Leaderboard / Social** — anonimowe porównanie per exercise w grupie wiekowej/wagowej
- **Apple Foundation Models** — lokalny model AI z aliasami z SDK jako słownik wsparcia
