# IPAD-00090 — Class Management Space

> Status: 🚧 **In progress** (~50% done). Update: 2026-06-17.
> Original plan: `~/.claude/plans/deep-mapping-milner.md` (refreshed below pod aktualny stan).

## Cel

Dedykowana przestrzeń w GymRoom (iPad app) do zarządzania klasami treningowymi:
1. **Grafik klas** — schedule template z `name`, `location`, optional `scheduledAt`, `maxParticipants`
2. **History** — past sessions z wykresami HR per athlete, calories ranking, time in zones (Apple Charts)
3. **NavigationSplitView** — iPad-idiomatic UX (sidebar + detail)

## Architectural changes vs original plan

| Decyzja | Oryginalny plan | Aktualny stan | Powód |
|---|---|---|---|
| GymClass semantics | Phase machine (`idle` / `live` / `past`) | Schedule template (pure data, no phase) | Klasy reusable (np. "Morning CrossFit" co wtorek), nie one-shot. Phase nie potrzebny — każde uruchomienie tworzy osobny session record w history. |
| Sidebar items | 3 tabs (Live Class / History / Create) | 2 tabs (Classes / History) | Create jako sheet z toolbar `+` w Classes — natywny iPad pattern (Reminders, Calendar). Live Class to fullScreenCover, nie sidebar item. |
| ClassCreation UX | Tab z form | Sheet z Form (toolbar `+`) | Sheet = modal, naturalny do "create" actions. Tab byłby zbyt prominent dla rzadkiej akcji. |
| `maxParticipants` | Hardcoded 8 | Device-aware z `BLECapacityClient` (PeerMirror module) | BLE limit per device (iPad Pro M-series 16, Air 5 12, pozostałe 8). User może override w granicach Apple practical cap (16). |
| ClassDetail rola | Tylko past classes (history detail) | Pre-class detail (location, scheduled, capacity) + Start button | Trener może sprawdzić capacity przed Start. Future: edit/delete klasy z toolbar. |

## Done

### Architecture
- ✅ `GymRoomRootFeature` z `NavigationSplitView` (sidebar: Classes / History)
- ✅ `LiveClassFeature` extracted z `GymRoomFeature` do `Features/LiveClass/`
- ✅ Feature splits zgodnie z konwencją: `+State.swift`, `+Action.swift`, `+CancelID.swift`, `+AlertState.swift`
- ✅ `ClassesListFeature` + `ClassesListView` (List z sekcjami, swipe-to-delete, fullScreenCover dla LiveClass)
- ✅ `ClassDetailFeature` + `ClassDetailView` (3 sekcje metadata, Start class button)
- ✅ `ClassCreationFeature` + `ClassCreationView` split 1→3 pliki z `///` na każdej property/case
- ✅ Schedule template: `GymClass` bez phase, klasy zostają w liście po End

### Model layer
- ✅ `GymClass` struct (id, name, location, scheduledAt?, maxParticipants, createdAt)
- ✅ `GymClassCapacity` enum (`default = 8`, `lowerBound = 1`, `upperBound = 16`)
- ✅ `BLECapacityClient` w **PeerMirror module** (public, `recommendedMaxConnections` + `upperBound`, sysctl `hw.machine` detection)

### UI / UX
- ✅ ClassesList grouped by day (`startOfDay` key, sorted chronologically)
- ✅ Section header: weekday leading + date footnote trailing (Apple Calendar style)
- ✅ "Without date" section dla klas bez `scheduledAt`
- ✅ Row layout: `name` leading + `time` trailing (HH:mm), subtitle = location
- ✅ Direct entry do LiveClass (tap row → fullScreenCover → auto-start w `viewDidAppear`)
- ✅ ClassDetailView (3 sekcje): LOCATION, SCHEDULED (optional), ATHLETES (`0/max`)
- ✅ Floating Start class button (green glass capsule, prawy dolny róg)
- ✅ ClassCreation Form: name, location, hasSchedule + DatePicker, Capacity Stepper
- ✅ Stepper z device-aware default + inline red error gdy `maxParticipants > deviceCapacity`
- ✅ Save disabled gdy `exceedsDeviceLimit || name.empty || location.empty`
- ✅ LiveClassView header: `0/8 athletes` z `store.maxParticipants` propagacją
- ✅ Empty state w ClassesList (`figure.cross.training` icon)

### Localization
- ✅ Klucze: Classes, History, Create, Class name, Location, Schedule, Scheduled, Capacity, Max athletes, Without date, Delete, This device supports up to %lld athletes, %lld/%lld athletes, Athletes
- ✅ "athletes" untranslated w PL (universal fitness term, user preference)
- ✅ Usunięcie stale keys: "Apple BLE peripheral limit — ..." (zastąpione conditional error footer)

## Pending

### Subtask B — Database schema (SQLiteData)
**Files NEW**:
- `AppDatabase/Sources/AppDatabase/Records/GymClassRecord.swift` — @Table, CloudKitSyncable
- `AppDatabase/Sources/AppDatabase/Records/AthleteSessionRecord.swift` — @Table z BLOB dla `hrSamplesData` + `aggregatedStatsData`
- `SharedModels/Sources/SharedModels/Analytics/HRSample.swift` — Codable struct (timestamp, bpm, activeEnergy)
- `SharedModels/Sources/SharedModels/Analytics/ClassAnalytics.swift` — Codable (avgHR, peakHR, totalCalories, durationSeconds, timeInZones)

**File MOD**:
- `AppDatabase/Sources/AppDatabase/Schema.swift` — append `v7_gymRoom` migration

**Decision pending**: `GymClass` (in-memory schedule template) vs `GymClassRecord` (persisted session). Czy schedule template też trafia do bazy (dla cross-launch persistence)?

### Subtask C — LiveClass persistence layer
- `GymClassClient` (dependency boundary nad SQLiteData queries)
- HR samples in-memory buffer (`[UUID: [HRSample]]` keyed by deviceID)
- Batch persist co 30s przez timer effect lub on `.peerSuspended/.peerDisconnected`
- `LiveClassFeature.State` extensions: `activeClassId`, `hrSamplesBuffer`
- On `.confirmEnd` → finalize all ongoing sessions, set `GymClassRecord.endedAt`

### Subtask D — ClassHistory real implementation
- Dziś: placeholder ContentUnavailableView ("History coming soon")
- TODO: List rows reverse-chrono (relative date "Today" / "Yesterday" / "Jun 13"), athlete count, duration
- Tap row → push ClassHistoryDetailView (osobny feature, NIE reused ClassDetailView)
- Empty state: "Brak klas w historii"

### Subtask E — ClassDetail z Apple Charts
**NEW** osobny `ClassHistoryDetailFeature` + `ClassHistoryDetailView` (różny od pre-class `ClassDetailView`):
- Top stats banner: total athletes, duration, total kcal, avgHR
- Bar chart: top calories burned per athlete (sorted desc, top 10)
- Line chart: HR over time per athlete (color per athlete, downsample 1Hz → 1/30Hz dla rendering)
- Pie chart: aggregated time in HR zones (5 colors z `HeartRateZone`)

### Subtask G — Localization sweep finalization
- Usuń stale keys (`extractionState: "stale"`) po build verification
- Confirm wszystkie user-facing texts przez `String(localized:, bundle: .main)`

## Out of scope (future tickets)

- **IPAD-0097** — CloudKit sync (`SyncEngine` dla `GymClassRecord` + `AthleteSessionRecord`)
- **IPAD-0094** — Multi-iPad (shared history w jednym boxie)
- **Privacy Manifest** + opt-in prompt (App Store ready release)
- **Athlete app per user** — peer-side history widoczna sportowcowi
- **Class templates** — predefined WOD'y ("Hero WOD Murph", "EMOM 20min")
- **Export PDF** — class report
- **Edit/Delete klasy z toolbar** w `ClassDetailView`

## Order of execution (next session)

1. **B → Database schema** (foundation dla wszystkiego dalej)
2. **C → LiveClass persistence** (hr buffer + batch persist)
3. **D → ClassHistory list real** (placeholder → real list)
4. **E → ClassHistoryDetail charts** (Apple Charts)
5. **G → Localization sweep finalization** (cleanup)

## Decisions deferred (do ustalenia)

- ❓ Czy `GymClass` (template) persistuje przez SwiftData/SQLiteData czy `@Shared(.appStorage)`? Aktualnie in-memory tylko, znika po app kill.
- ❓ Czy `ClassDetailView` (pre-class) ma toolbar Edit/Delete?
- ❓ Czy crash recovery dla `GymClassRecord.endedAt == nil` (ongoing forever) — defensive `WHERE endedAt IS NULL → set endedAt = updatedAt` na app launch?
- ❓ Czy `BLECapacityClient.recommendedMaxConnections()` ma być też runtime enforcement w `PeerMirrorBLEHostSession` (reject peer'a gdy `connectedCount >= limit`)?

## Notes

- **PeerMirror.BLECapacityClient** zaprojektowany dla dual-use: UI default + future runtime enforcement. Jeśli enforce w hostSession → trzeba też emitować `.rejectedPeer(reason: .capacityFull)` event do GymRoom (user widzi że ktoś próbował dołączyć ale klasa pełna).
- **Schedule template + session records** to dwa różne modele. `GymClass` = template (re-usable), `AthleteSessionRecord` + `GymClassRecord` = persisted runtime data. Konwersja w `LiveClassFeature.startTapped` → create `GymClassRecord` z `gymClass.id` jako FK.
- **Day header DateFormatter** używa current locale (PL → "Środa", EN → "Wednesday"). Auto-rotacja po system language change.
- **Apple Charts performance** dla long sessions (60min @ 1Hz = 3600 points × 10 athletes = 36k points line chart) — downsample do 1/30Hz dla rendering OK w subtask E.
- **iOS 26-only** — wszystkie features wykorzystują iOS 26 SDK bez fallbacków (per project policy).
