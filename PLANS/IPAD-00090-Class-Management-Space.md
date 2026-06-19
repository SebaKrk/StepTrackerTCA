# IPAD-00090 — Class Management Space

> Status: 🚧 **In progress** (~95% done). Update: 2026-06-18 (Subtask E charts done).
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

### ~~Subtask B — Database schema (SQLiteData)~~ ✅ Done (2026-06-17)

**Decision made**: 3-tabele model (`GymClassRecord` template + `ClassSessionRecord` runtime + `AthleteSessionRecord` peer). Template persistuje, snapshot `className` + `location` w session record (immune na późniejsze rename template'a).

**Files created**:
- ✅ `AppDatabase/Sources/AppDatabase/Records/GymClassRecord.swift` — template (id, name, location, scheduledAt?, maxParticipants)
- ✅ `AppDatabase/Sources/AppDatabase/Records/ClassSessionRecord.swift` — runtime (id, gymClassId FK, className snapshot, location snapshot, startedAt, endedAt?)
- ✅ `AppDatabase/Sources/AppDatabase/Records/AthleteSessionRecord.swift` — peer (id, classSessionId FK, deviceID, nick, maxHR, hrSamplesData BLOB, aggregatedStatsData BLOB, joinedAt, leftAt?)
- ✅ `SharedModels/Sources/SharedModels/Analytics/HRSample.swift` — Codable (timestamp, bpm, activeEnergy)
- ✅ `SharedModels/Sources/SharedModels/Analytics/ClassAnalytics.swift` — Codable (avgHR, peakHR, totalCalories, durationSeconds, timeInZones: `[HeartRateZone: TimeInterval]`)
- ✅ `AppDatabase/Sources/AppDatabase/Schema.swift` — migration `v7_gymRoom` (3 tabele + 4 indexy: gymClassId, startedAt, classSessionId, deviceID)

**Indexes rationale**:
- `classSessionRecords.gymClassId` → query "all sessions for this template"
- `classSessionRecords.startedAt` → ORDER BY DESC dla History list (reverse-chrono)
- `athleteSessionRecords.classSessionId` → query "all athletes in this session"
- `athleteSessionRecords.deviceID` → future query "all sessions for this peer"

### ~~Subtask C — LiveClass persistence layer~~ ✅ Done (2026-06-17, branch C)

**Architecture**: 3-etap wire — Client + ClassesList + LiveClass.

**Files NEW**:
- ✅ `GymRoom/Client/GymClassClient.swift` — TCA boundary, **8 closure'ów** (templates: fetch/save/delete, sessions: start/end, athletes: add/appendHR/end)
- ✅ `GymRoom/Mapping/GymClass+Record.swift` — `init(domain:updatedAt:)` + `toDomain()`
- ✅ `SharedModels/Analytics/ClassAnalytics+Compute.swift` — `static let empty` + `compute(samples:maxHR:duration:)` (avgHR, peakHR, totalCalories = last-first delta, timeInZones iteration)

**Files MODIFIED (ClassesList wire)**:
- ✅ `ClassesListFeature.swift` — `viewDidAppear` → fetch, `classCreated` → save, `classDeleteTapped` → delete (optimistic + async)
- ✅ `ClassesListFeature+Action.swift` — `viewDidAppear` (View) + `classesLoaded([GymClass])` (internal)
- ✅ `ClassesListView.swift` — `.task { send(.viewDidAppear) }`

**Files MODIFIED (LiveClass wire)**:
- ✅ `LiveClassFeature.swift` — wire session lifecycle:
  - `startTapped` → `startSession()` + `sessionStarted` callback
  - `sessionStarted` → start 30s persistenceTimer
  - `peerConnected` → `addAthlete()` (maxHR=190 default)
  - `sampleReceived` → buffer push
  - `flushBufferedSamples` → batch `appendHRSamples` per peer
  - `peerDisconnected` → flush + `endAthlete` (analytics)
  - `confirmEnd` → final flush + `endSession` (finalize ongoing) + cancel timer
- ✅ `LiveClassFeature+State.swift` — `activeSessionId`, `athleteRecordIds: [UUID: UUID]`, `hrSamplesBuffer: [UUID: [HRSample]]`, `gymClassId`
- ✅ `LiveClassFeature+Action.swift` — `sessionStarted(UUID)`, `athleteAdded(deviceID, athleteId)`, `flushBufferedSamples`
- ✅ `LiveClassFeature+CancelID.swift` — `case persistenceTimer`

**Known MVP limitations** (osobne tickety):
- `maxHR=190` hardcoded przy `addAthlete` — precise per-athlete maxHR update na first sample = future
- Crash window max 30s utraconych próbek (buffer flush interval)
- Brak retry logic dla failed DB writes (Logger.error only)

### Subtask D — ClassHistory real implementation
- Dziś: placeholder ContentUnavailableView ("History coming soon")
- TODO: List rows reverse-chrono (relative date "Today" / "Yesterday" / "Jun 13"), athlete count, duration
- Tap row → push ClassHistoryDetailView (osobny feature, NIE reused ClassDetailView)
- Empty state: "Brak klas w historii"

### Subtask E — ClassDetail z Apple Charts

**NEW** osobny `ClassHistoryDetailFeature` + `ClassHistoryDetailView`. Tap row w History → push do detail (`NavigationStack` push w obrębie History tab).

**Layout sekcji (top → bottom)**:

1. **Top stats banner** — HStack z 4 stat cards (read-only, computed z `[AthleteSessionRecord]`):
   - Total athletes (count)
   - Duration (z `classSessionRecord.endedAt - startedAt`)
   - Total calories burned (sum across all athletes z `aggregatedStats.totalCalories`)
   - Average HR (average z `aggregatedStats.avgHR` across athletes)

2. **HR over time** — kluczowa sekcja z **toggle widoku** (Picker SegmentedControl):
   - **Tab "Per athlete"** — `ScrollView` z N kart, każda karta = jeden athlete:
     ```
     ┌────────────────────────────────────┐
     │ SebaB98          avgHR 71 · peak 73│
     │ ╭──────────────────────────────╮   │
     │ │ ─────────(mini line chart)   │   │
     │ ╰──────────────────────────────╯   │
     └────────────────────────────────────┘
     ```
     User widzi indywidualny przebieg HR każdego sportowca z jego unique color.
   - **Tab "Combined"** — jeden duży line chart z **wszystkimi athletes** jako multi-series (`series: .value("Athlete", nick)` + `.foregroundStyle(by:)`) + auto-generated legend:
     ```
     ┌──────────────────────────────────────┐
     │ ─── SebaB98                          │
     │ ─── Karolina                         │
     │ ─── Marek                            │
     │ [multi-series line chart]            │
     └──────────────────────────────────────┘
     ```
     User widzi porównanie wszystkich athletes na jednej skali czasu.
   - State: `enum ChartViewMode { case perAthlete, combined }` w State, default `.combined`

3. **Calories burned** — bar chart (Apple Charts) per athlete, sorted descending. Zawsze "combined view" (lista wszystkich athletes z bar'em proporcjonalnym do `totalCalories`).

4. ~~**Time in zones** — pie chart z aggregated time across all athletes~~ ❌ Removed per user decision (2026-06-18) — nie potrzebne w MVP detail view. Jeśli kiedyś będzie potrzeba intensywności analytics, można dodać back jako toggle/expandable section. Aktualnie `ClassAnalytics.timeInZones` dalej **jest** computed i persistowany w BLOB (na wypadek future use), tylko UI section usunięta.

**Files NEW**:
- `Features/ClassHistory/Child/ClassHistoryDetail/Feature/ClassHistoryDetailFeature.swift`
- `Features/ClassHistory/Child/ClassHistoryDetail/View/ClassHistoryDetailView.swift`
- Plus może components: `View/Components/HRChartPerAthleteCard.swift`, `HRChartCombinedSection.swift`

**Files MODIFIED**:
- `GymClassClient.swift` — + `fetchAthletesForSession(sessionId: UUID) async throws -> [AthleteSessionRecord]`
- `AthleteSessionRecord` — + `Sendable` conformance (tak jak `ClassSessionRecord` z D)
- `ClassHistoryFeature` — + `@Presents var detail: ClassHistoryDetailFeature.State?` + handle `classRowTapped` action
- `ClassHistoryView` — make row tappable + navigation destination

**Performance considerations** (real klasy mogą mieć 10 athletes × 60min):
- Downsample raw `[HRSample]` (~5s interval) z BLOB do display rate (~30s interval) dla rendering. Raw zostaje w bazie, downsampled tylko dla chart.
- Charts framework optymalny dla ~5k points; 10 athletes × 720 points (60min @ 5s) = 7200 points — borderline. Downsample do 1/30s = ~120 points/athlete × 10 = 1200 total — fast.
- Decode JSON `hrSamplesData` BLOB async w `.run` effect (nie sync w View body).

**Konkretne pattern dla "Per athlete" mini chart** (Apple Charts):
```swift
Chart(samples) { sample in
    LineMark(
        x: .value("Time", sample.timestamp),
        y: .value("BPM", sample.bpm)
    )
    .foregroundStyle(athlete.color)  // deterministic per deviceID
}
.frame(height: 80)  // mały, mieści się w karcie
```

**Konkretne pattern dla "Combined" multi-series**:
```swift
Chart {
    ForEach(athletes) { athlete in
        ForEach(athlete.samples) { sample in
            LineMark(
                x: .value("Time", sample.timestamp),
                y: .value("BPM", sample.bpm),
                series: .value("Athlete", athlete.nick)
            )
            .foregroundStyle(by: .value("Athlete", athlete.nick))
        }
    }
}
.chartLegend(position: .bottom)
```

**User requirement (potwierdzony 2026-06-18)**: switch tab/picker między dwoma trybami HR chart jest kluczowy — trener chce widzieć indywidualne przebiegi (problem detection per athlete) i porównanie wszystkich (kto się rozkręcił, kto został w resting). Calories i zones zostają jako global views.

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

1. ~~**B → Database schema**~~ ✅ Done
2. ~~**C → LiveClass persistence**~~ ✅ Done (end-to-end verified 2026-06-18, 28 HR samples + analytics persisted)
3. ~~**D → ClassHistory list real**~~ ✅ Done (2026-06-18, minimal wersja):
   - `fetchAllSessions` w GymClassClient (ORDER BY startedAt DESC)
   - `ClassHistoryFeature` + `ClassHistoryView` (single-file reducer, NavigationStack + List)
   - Row layout: className + date (Today/Yesterday/dMMM) + subtitle "location · duration"
   - Empty state ContentUnavailableView gdy 0 sessions
   - Replaced `ClassHistoryPlaceholderView` → wired w `GymRoomRootView`
   - Brak detail push (subtask E doda push z charts)
4. **E → ClassHistoryDetail charts** (Apple Charts)
5. **G → Localization sweep finalization** (cleanup)
6. **Bug fixes** (z testów end-to-end C):
   - ~~**Fix endSession cancellation race condition**~~ ✅ Fixed (2026-06-18, w scope D) — refactor `confirmEnd` w `LiveClassFeature.swift`: emit `delegate.classEnded` **w środku** `.run` po wszystkich await'ach (flush + endSession + stopAdvertising). Parent dismiss child **dopiero po** completion persistence cleanup. Teraz `classSessionRecords.endedAt` poprawnie set'owany przy End class.
   - **Fix `timeInZones` JSON format** — Swift's `Codable` dla `[HeartRateZone: TimeInterval]` Dictionary encoduje jako flat array `[key, value]` zamiast keyed object. Round-trip działa, ale JSON brzydki. Fix: custom `Codable` w `ClassAnalytics` lub zamiana na `[String: TimeInterval]`.

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
