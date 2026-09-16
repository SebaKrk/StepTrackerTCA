---
date: 2026-08-31T16:54:56+0200
researcher: Claude (Fable 5) + Sebastian Ściuba
git_commit: bb57db0582984d4bc5cf6eaebe1ab702ea6873a5
branch: dev/10xDev/lesson2.5
repository: StepTrackerTCA (MyFitnessJournal)
topic: "S-02 record-entry-current-pr: zapis wpisu PR z metadanymi + czysta funkcja currentPR (migracja v12)"
tags: [research, codebase, appdatabase, migration, pr-board, form-patterns, sqlite-data]
status: complete
last_updated: 2026-08-31
last_updated_by: Claude (Fable 5)
---

# Research: S-02 — zapis wpisu i wyznaczanie aktualnego PR

**Date**: 2026-08-31T16:54:56+0200
**Git Commit**: bb57db0 (`lesson2.4 (p7)`)
**Branch**: dev/10xDev/lesson2.5

## Research Question

Grunt pod S-02 (US-01, FR-004/005/007/009/012): (1) warstwa bazy — wzorzec migracji v12, rekordu i klienta; (2) wzorce formularza zapisu z walidacją + snapshot masy ciała + kontrolki; (3) research zewnętrzny — changelog sqlite-data 1.6.x→najnowsza przed pierwszą nową migracją (follow-up health-check).

## Summary

- **Research zewnętrzny rozstrzygnięty**: sqlite-data 1.6.x (pin: 1.6.1/1.6.2) → 1.11.2 (29 sie) — **zero breaking changes**, zero zmian w `DatabaseMigrator`/`@Table`; nowości to dodatki (`@FetchAll(sectionBy:)`, auto-obserwacja `@FetchOne`, wydajność `@Fetch*`). Migrację v12 piszemy bezpiecznie na obecnym pinie; upgrade = osobna zmiana poza S-02.
- **Wzorzec migracji jest żelazny** (11 przykładów): `registerMigration("v12_...")` wpinany w `Schema.swift` po v11 (`:336`), przed `migrate` (`:338`); tabela `STRICT`, `"id" TEXT NOT NULL PRIMARY KEY ON CONFLICT REPLACE`, obowiązkowe ogony `createdAt`/`updatedAt` TEXT + `ckRecordData` BLOB (furtka `CloudKitSyncable` — protokół 3 pól, `CloudKitSyncable.swift:19`), **zero FOREIGN KEY** — relacje luźne przez kolumny TEXT + indeksy `index_<tabela>_on_<kolumna>`.
- **Wzorzec klienta**: ręczny struct z closure props (bez `@DependencyClient`), `liveValue` jako IIFE z `@Dependency(\.defaultDatabase)`, zapis `database.write { }` + `Record.upsert { Draft }`, `testValue` z `unimplemented(...)` — szablon: `ExerciseLogClient.swift:16-114`; wariant atomowego read+write w jednej transakcji: `ClassParticipationClient.swift:58-81`.
- **Odświeżanie po zapisie**: dominujący wzorzec = imperatywny refetch przy `viewDidAppear` (ExerciseAnalytics/ExerciseDetail); jedyny precedens `@FetchAll` w State: `PersonalActivityFeature+State.swift:54-69` (`@ObservationStateIgnored @FetchAll(...)`, baza sama pushuje po każdym zapisie). Dla liczników kategorii i wartości PR w wierszach — decyzja przy planie.
- **Masa ciała**: `PersonalDataClient.getWeightForDate: (Date) async throws -> HealthKitData?` (kg potwierdzone, `HealthKitData.value: Double`) — istnieje i ma **zero produkcyjnych wywołań** (idealny, nieużywany hak); klient bez `testValue`/`previewValue` (previewy robią lokalny stub, `SessionView.swift:419,477`). Styl wywołania nieblokującego: `(try? await ...) ?? nil` (`SessionFeature+Lifecycle.swift:168`).
- **Formularz**: najlepszy wzorzec = `ExerciseEditor` (draft + `originalDraft`, `isSaveDisabled` w State, `ViewAction+BindableAction`, `delegate(.saved(...))`, `.disabled(store.isSaveDisabled)` na Save w toolbarze); prostszy wariant, gdzie **dziecko samo persystuje** przez klienta: `PersonProfileEditFeature.swift:30-43`. Wpis kg w repo: TextField `String` + `.decimalPad` (SetTable/InlineResultEditor) LUB `Stepper` Int kg (ExerciseEditor:212-250).
- **RPE i sprzęt: zero istniejącego UI i modelu** (grep czysty; jedyne trafienia to słownik tokenów AI w WorkoutVocabulary). `ScalingType` (rx/scaled/rxPlus) istnieje w modelu, ale **nigdzie nie ma pickera** — każdy zapis to literał; badge "RX" to zwykły tertiary text (`ExerciseList.swift:111-122`). Formularz S-02 buduje te kontrolki od zera.
- **Punkty wpięcia w PRBoard** (dokładne): szczegół — `PRMovementDetailFeature.swift:15-24` (State tylko `movement`, pusty `enum Action {}`, `EmptyReducer` — do zastąpienia; widok bez `@Bindable`/`@ViewAction`/`.sheet`); licznik kategorii — literał `"0/"` w `PRBoardView.swift:89`; wartość PR w wierszu — `PRMovementListView.swift:91` (`emptyResultPlaceholder`); `ContentUnavailableView` w szczególe ma nieużywany slot `actions:` (naturalne miejsce na przycisk "dodaj pierwszy wynik").
- **Testy czystej funkcji**: jedyny pakiet z testami i jedyny w matrixie CI to **SharedModels** → czysta funkcja `currentPR` powinna mieszkać w SharedModels (obok `PRCatalog`), żeby jej testy jechały w `swift test` i w CI bez żadnych zmian w workflow.

## Detailed Findings

### 1. Migracja v12 i rekord (AppDatabase)

- `bootstrapDatabase()` — `Schema.swift:28-344`: otwarcie bazy → `eraseDatabaseOnSchemaChange` w DEBUG (`:32-34`) → v1–v11 → `migrate` (`:338`) → `defaultDatabase = database`. **Miejsce v12: po `:336`, przed `:338`.**
- Wzorzec pełnej migracji: `v11_classParticipation` (`Schema.swift:310-336`) — komentarz-uzasadnienie nad `registerMigration`, `#sql("""CREATE TABLE ... STRICT""").execute(db)` + `CREATE [UNIQUE] INDEX`.
- Reguła append-only spisana w samym pliku: `Schema.swift:147-150` („never edit an already-registered migration body… Always append a new vN"). ALTER TABLE-owe przykłady: v2/v6/v10.
- Wzorzec rekordu: `ClassParticipationRecord.swift` (123 linie — najlepszy szablon) i `ExerciseLogRecord.swift:22-252` — `@Table` + `Identifiable, CloudKitSyncable` (+`Sendable` w nowszych), `id: UUID`, enumy jako String rawValue, sekcja `// MARK: - CloudKitSyncable`, explicit init z `ckRecordData: Data? = nil` na końcu, extension `// MARK: - Mapping` (`init(from:createdAt:updatedAt:)` + `toDomain()`).
- Testów AppDatabase brak (żadnego `.testTarget`) — health-check fix #4 (test migratora v1→vN na in-memory) pozostaje otwarty; decyzja przy planie, czy dokładać w S-02.

### 2. Klient i odświeżanie

- `ExerciseLogClient.swift`: `struct ... : Sendable` z `var save: @Sendable ([ExerciseLog]) async throws -> Void` itd. (`:16-21`); `DependencyValues` extension internal (`:25-30`); `liveValue` IIFE z `@Dependency(\.defaultDatabase)` (`:34-37`); zapis: pętla w JEDNYM `database.write` = jedna transakcja, `Record.upsert { Draft }` (`:44-73`); fetch: `database.read` + `Record.where{}.order{}.fetchAll.map(toDomain)` (`:77-103`); `testValue` computed var z `unimplemented` (`:107-114`).
- Wołanie z SummaryFeature: capture list w `.run` (`SummaryFeature.swift:169`), błąd zapisu → `reportIssue(error)` bez przerywania flow (`:282-288`), po zapisie `dismiss()` — rodzic refetchuje przy `viewDidAppear`.
- `@FetchAll` w State — jedyny precedens: `PersonalActivityFeature+State.swift:54-69` (`@ObservationStateIgnored @FetchAll(Record.where{...}) var x` bez adnotacji typu; uzasadnienie w doc: filtr w SQLite + push po każdym zapisie). `@FetchOne`/`@Fetch` — brak w repo.

### 3. Masa ciała (snapshot)

- `PersonalDataClient.swift:18-19`: `getWeight(Int daysLookback)`, `getWeightForDate(Date)` → `HealthKitData?` (`value: Double` w kg — `DefaultPersonalDataManager.swift:105,136,157` `.gramUnit(with: .kilo)`).
- Brak `testValue`/`previewValue` — previewy stubują lokalnie (`SessionView.swift:419,477`). Wzorzec nieblokujący: `(try? await ...) ?? default` (`SessionFeature+Lifecycle.swift:168-169`). Zgodne z kryterium US-01: „brak zgody nie blokuje zapisu".

### 4. Formularz (wzorce do złożenia)

- **ExerciseEditor** (pełny wzorzec draft+walidacja): State `mode/originalDraft/draft/isSaveDisabled` (`ExerciseEditorFeature+State.swift:21-60`), Action `ViewAction, BindableAction` + `delegate(.saved(...))` (`+Action.swift:15-67`), reducer `BindingReducer()` + save→delegate→dismiss (`ExerciseEditorFeature.swift:22-47`), widok `ScrollView+GroupBox+styledGroupBox`, Save w toolbarze z `.disabled(store.isSaveDisabled)` (`ExerciseEditorView.swift:57-65`), picker `.pickerStyle(.menu)` (`:140-160`), kg przez `Stepper` Int 1...500 (`:212-250`), notatka `TextField(axis: .vertical).lineLimit(2...)` (`:274-284`).
- **PersonProfileEdit** (prostszy; dziecko samo persystuje): `Form` + Cancel/Save w toolbarze, `try await client.save` w dziecku → `delegate(.profileSaved)` → dismiss (`PersonProfileEditFeature.swift:30-46`); prezentowany `.sheet` przez Destination rodzica.
- Kontrolki kg w repo: `SetTable.numericField` = TextField `String` + `.decimalPad` + syntetyczny Binding (`SetTable.swift:129-153`); `InlineResultEditor.weightField` → `fieldWithUnit(unit:"kg")` (`InlineResultEditor.swift:222-243,299-316`); alternatywa `Stepper` Int kg (ExerciseEditor).
- Notatka: gotowy komponent `NoteRow` (`UI/Summary/NoteRow.swift:13`, 3 fazy empty→editing→saved).
- **RPE / sprzęt: brak jakiegokolwiek UI i pól modelu** — do zbudowania od zera (kształt kontrolki = pytanie planu). `ScalingType.displayName` NIEzlokalizowany, hardcoded (`ScalingType.swift:9-15`); brak pickera rx/scaled w całym repo.

### 5. Punkty wpięcia w PRBoard (stan po S-01)

- Szczegół: `PRMovementDetailFeature.swift:15-24` — State `let movement`, `enum Action {}` (komentarz „No actions in S-01"), `EmptyReducer`; brak plików `+State/+Action` (jedyny feature bez splitu); widok `let store` bez `@Bindable`/`@ViewAction`, bez `.toolbar`/`.sheet` (`PRMovementDetailView.swift:13-19`); `emptyState` = `ContentUnavailableView` z nieużywanym slotem `actions:` (`:79-86`).
- Licznik kategorii: literał `Text("0/\(...count)")` — `PRBoardView.swift:89`; slot „ostatni PR" = `lastRecordPlaceholder` (`:98-102`). `PRBoardFeature.State` nie ma źródła danych ani akcji ładowania.
- Wiersz listy: `movementRowLabel` (`PRMovementListView.swift:84-96`), wartość = `emptyResultPlaceholder` (`:98-102`); sekcje liczone ze statycznego katalogu (`PRMovementListFeature+State.swift:19-27`).
- Model katalogu gotowy pod formularz: `PRScoreType` (weight/time/reps/amrap) steruje kontrolką; `supportsRxScaled` gate'uje picker Rx/scaled (`PRMovement.swift:12-17,54-66`).

### 6. Research zewnętrzny — sqlite-data

- Pin: 1.6.1 (AppDatabase) / 1.6.2 (HealthHub) — `Package.resolved`; repo `pointfreeco/sqlite-data`.
- Releases 1.7.0→1.11.2 (źródło: github.com/pointfreeco/sqlite-data/releases, odczyt 2026-08-31): brak breaking changes, brak zmian DatabaseMigrator/@Table; nowości: traity CasePaths/Tagged (1.7), `@FetchAll(sectionBy:)` (1.8), floors platform (1.9), auto-obserwacja `@FetchOne` + `StrictDecoding` (1.10), `ColumnCoding` + wydajność `@Fetch*` (1.11), fixy CloudKit (1.11.1).
- **Decyzja researchu: v12 na obecnym pinie; upgrade biblioteki = osobny, opcjonalny ticket.**

## Code References

- `AppDatabase/Sources/AppDatabase/Schema.swift:28-344` — bootstrap + wzorzec migracji; v12 wchodzi po `:336`
- `AppDatabase/Sources/AppDatabase/CloudKitSyncable.swift:19` — furtka (3 pola)
- `AppDatabase/Sources/AppDatabase/Records/ClassParticipationRecord.swift` — szablon nowego rekordu
- `WorkoutMirrorLive/FeaturesNew/WorkoutTab/Session/Client/ExerciseLogClient.swift:16-114` — szablon klienta
- `HealthHub/Sources/HealthHub/ClassParticipation/ClassParticipationClient.swift:58-81` — atomowy read+write
- `WorkoutMirrorLive/FeaturesNew/StatsTab/Child/PersonSettings/Client/PersonalDataClient.swift:18-19` — snapshot masy ciała
- `WorkoutMirrorLive/FeaturesNew/.../ExerciseEditor/` — wzorzec formularza z walidacją
- `WorkoutMirrorLive/FeaturesNew/PRBoard/...` — punkty wpięcia (PRBoardView.swift:89, PRMovementListView.swift:91, PRMovementDetailFeature.swift:15-24)
- `SharedModels/Sources/SharedModels/SharedModels/PRCatalog/PRMovement.swift:12-17` — PRScoreType/supportsRxScaled
- `WorkoutMirrorLive/FeaturesNew/ActivitiesTab/.../PersonalActivityFeature+State.swift:54-69` — precedens @FetchAll

## Architecture Insights

- **Czysta funkcja `currentPR` powinna żyć w SharedModels** (obok PRCatalog): to jedyny pakiet z testami i jedyny w matrixie CI — testy funkcji wchodzą do `swift test` i CI bez zmian w workflow. Domenowy typ wpisu (np. `PREntry`) też w SharedModels; rekord DB + klient w AppDatabase/app targecie (podział jak ExerciseLog: model w SharedModels, `ExerciseLogRecord` w AppDatabase).
- Dwa spójne warianty odpowiedzialności za zapis: dziecko-formularz persystuje samo (PersonProfileEdit) vs delegate do rodzica (ExerciseEditor). Dla PR: szczegół ruchu i tak musi się odświeżyć po zapisie — decyzja przy planie razem z wyborem refresh (imperatywny vs @FetchAll).
- Lekcja z lessons.md obowiązująca wprost: „nowa migracja w DEBUG kasuje dane na urządzeniu dev — zaplanuj moment + backup" (incydent 03.08) oraz „migracje append-only". Obie muszą trafić do planu jako jawne punkty.
- Reducer formularza: wyłącznie kontrolowane zależności (`@Dependency(\.date)`, `\.uuid`, kliency) — reguła lessons.md; data „domyślnie dziś" z `\.date.now`, id wpisu z `\.uuid`.

## Historical Context (from prior changes)

- `context/archive/2026-08-30-shared-result-input-components/` (F-01) — kontrolki wejściowe w `UI/ResultEntry/` (SetTable z trybem edycji kg, TimePickerField, DNFFields) + motyw; dla S-02 (tylko ciężar) najistotniejszy jest wzorzec pola kg.
- `context/archive/2026-08-31-pr-board-entry-and-catalog/` (S-01) — ekrany i katalog, w które S-02 się wpina; plan S-01 celowo zostawił szczegół „czekający na formularz".
- `context/foundation/health-check.md` — fix #2 (changelog przed v12: ZAMKNIĘTY tym researchem), fix #4 (testTarget AppDatabase z testem migracji: wciąż otwarty).

## Related Research

- `context/archive/2026-08-31-pr-board-entry-and-catalog/research.md` — toolbar/katalog/wzorce feature'ów
- `context/foundation/roadmap.md` — S-02 (gwiazda), Prerequisites: S-01 ✓, F-01 ✓
- `context/foundation/prd.md` — FR-004/005/007/009/012, US-01, Business Logic Changes

## Open Questions

1. **Zakres S-02 vs typy wyników**: rdzeń czystej funkcji dla `weight` teraz, czy od razu pełna funkcja (time/reps/amrap + Rx/scaled) z UI tylko dla weight? (S-03/S-04 i tak przyjdą — funkcja od razu kompletna = testy raz, a UI przyrostowo.) → decyzja przy planie.
2. **Model sprzętu**: US-01 wymaga „ikony sprzętu" na szczególe → sugeruje enum (np. none/belt/…), nie wolny tekst. Kształt listy = decyzja użytkownika przy planie.
3. **RPE**: skala i kontrolka (np. 6–10 co 0.5? picker menu?) — brak precedensu w repo. → decyzja przy planie.
4. **Refresh**: imperatywny refetch (dominujący wzorzec) vs `@FetchAll` (precedens PersonalActivity; liczniki kategorii aktualizują się same). → decyzja przy planie.
5. **Test migracji v12** (health-check fix #4): dokładać `.testTarget` AppDatabase w S-02 czy osobno? (Reguła repo: bez proaktywnych testów — ale test migratora jest wpisany w lessons.md jako „przy pierwszej okazji".) → decyzja przy planie.
