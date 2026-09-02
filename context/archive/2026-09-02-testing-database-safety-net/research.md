---
date: 2026-09-02T14:36:42+02:00
researcher: Claude Code (Fable 5)
git_commit: 70f8e978f14b32de9be4abe1f6b05fc86341b54c
branch: dev/10xDev/lesson3.1
repository: StepTrackerTCA
topic: "Ugruntowanie Fazy 1 test-planu: Risk #2 (migracja niszczy dane) i Risk #3 (wpis ginie cicho między formularzem a bazą)"
tags: [research, codebase, app-database, migrations, sqlite-data, pr-board, records]
status: complete
last_updated: 2026-09-02
last_updated_by: Claude Code (Fable 5)
---

# Research: Siatka bezpieczeństwa bazy — ugruntowanie ryzyk #2 i #3

**Date**: 2026-09-02T14:36:42+02:00
**Researcher**: Claude Code (Fable 5)
**Git Commit**: 70f8e978f14b32de9be4abe1f6b05fc86341b54c
**Branch**: dev/10xDev/lesson3.1
**Repository**: StepTrackerTCA

## Research Question

Ground rollout Phase 1 of `context/foundation/test-plan.md`. Zweryfikować (nie przyjmować ślepo) wskazówki odpowiedzi dla: **Risk #2** — migrator przechodzi v1→vN na bazie Z DANYMI poprzedniej wersji i dane przeżywają (challenge: „test na pustej bazie wystarczy"); **Risk #3** — round-trip wpisu zwraca identyczne wartości, niepełne/nieznane dane nie znikają cicho (challenge: „kompiluje się = mapuje się"). Zlokalizować istniejące testy, wskazać najtańszą użyteczną warstwę, oflagować ryzyka spekulatywne.

## Summary

- **Risk #2 POTWIERDZONE, guidance poprawne.** Obecny test migratora (`MigratorTests.swift`) jest **strukturalnie ślepy** na scenariusz incydentu 2026-08-03: startuje z pustej bazy in-memory i sprawdza tylko istnienie tabeli `prEntryRecords`. Mechanizm incydentu (DEBUG `eraseDatabaseOnSchemaChange` + `hasSchemaChanges` → `db.erase()`) materializuje się wyłącznie na bazie z zastosowanymi migracjami. Fixture „baza v11 Z DANYMI → migracja do v12 → dane przeżyły" jest **tanio wykonalny w `swift test`**: `AppDatabaseSchema.makeMigrator()` jest publiczny, a GRDB 7.10.0 ma `migrate(_:upTo:)`. Bonus: asercja `hasSchemaChanges == false` testuje dokładnie predykat decydujący o erase — łapie każdą edycję historycznej migracji.
- **Risk #3 CZĘŚCIOWO POTWIERDZONE, guidance skorygowane.** Mapowanie zapisu `PREntryRecord.init(from:)` jest bezstratne, ale odczyt `toDomain()` ma cztery stratne przejścia (nil-collapse całego wpisu, ciche odfiltrowanie sprzętu, ciche przepisanie kontekstu na `.fresh`), a `compactMap` w trzech State'ach czyni każdy defekt danych **niewidzialnym bez żadnej telemetrii**. Dziś bez triggera (editor tworzy tylko `.weight`, formularz gwarantuje spójność) — realne przy: rename rawValue, przyszłym CloudKit sync, migracji ALTER. **Korekta warstwy**: round-trip w pakiecie AppDatabase testuje rekord+SQL; klient (`PREntryClient` — ręczna kopia 16 pól do Draft) i reducer żyją w app targecie, poza zasięgiem `swift test`.
- **Najpoważniejsze znalezisko poza pierwotnym sformułowaniem ryzyka**: „zapis udaje sukces" istnieje dosłownie — `PREntryEditorFeature` łapie błąd zapisu w `catch { reportIssue(error) }` (no-op w RELEASE) i **bezwarunkowo robi `dismiss()`** — nieudany zapis wygląda dla użytkownika identycznie jak sukces. Precedens aktywnej cichej straty już istnieje w `ExerciseLogRecord` (podwójne `try?` na JSON blob — drift `SetEntry` = utrata historii serii bez śladu).

## Detailed Findings

### Migrator i semantyka DEBUG erase (Risk #2)

- Wszystkie 12 migracji w `AppDatabase/Sources/AppDatabase/Schema.swift`: rejestracja w `AppDatabaseSchema.makeMigrator()` (`Schema.swift:48-50`), komentarz: „single source of truth shared by bootstrapDatabase() and the migrator test".
- Migracje są w 100% addytywne: `CREATE TABLE ... STRICT` + `CREATE INDEX` (v1, v3–v5, v7–v9, v11, v12) oraz `ALTER TABLE ... ADD COLUMN` nullable/DEFAULT (v2 `Schema.swift:68-74`, v6 `:168-177`, v10 `:312-325`). Zero DROP/UPDATE/DELETE.
- `bootstrapDatabase()` (`Schema.swift:28-43`): `eraseDatabaseOnSchemaChange = true` ustawiane **tylko w `#if DEBUG`** i **tylko w bootstrap** (`:32-34`) — `makeMigrator()` zwraca czysty migrator (domyślnie erase=false), więc testy dostają wariant bezpieczny i mogą jawnie włączyć flagę, by zasymulować ścieżkę DEBUG.
- Mechanizm erase (GRDB 7.10.0, checkout `GRDB/Migration/DatabaseMigrator.swift:646-660`): `migrate()` najpierw woła `hasSchemaChanges(db)`; true → **`db.erase()`** (cała zawartość). `hasSchemaChanges` (`:427-464`) → true gdy: zastosowana migracja o nieznanej nazwie LUB dowolny diff `sqlite_master` względem świeżo zmigrowanej bazy tymczasowej (czyli także edycja treści zarejestrowanej migracji).
- Ostrzeżenie w samym kodzie: `Schema.swift:165-167` — „never edit an already-registered migration body…".

### Obecny test migratora — czego NIE łapie

- `AppDatabase/Tests/AppDatabaseTests/MigratorTests.swift:16-28`: `DatabaseQueue()` (pusta in-memory) → `makeMigrator().migrate(database)` → asercja: `sqlite_master` zawiera `prEntryRecords`.
- **Teza z test-planu potwierdzona**: na pustej bazie `hasSchemaChanges` nie ma czego porównywać; „aplikuje się czysto od zera" jest prawdą zarówno przed, jak i po zmianie, która wyzwoliła incydent. Zero danych, zero scenariusza upgrade'u, zero sprawdzenia innych tabel.

### Wykonalność fixture'a „baza z danymi" (Risk #2 — najtańsza warstwa)

- GRDB **7.10.0** (`AppDatabase/Package.resolved`), SQLiteData 1.6.1.
- `migrate(_:upTo:)` — `GRDB/Migration/DatabaseMigrator.swift:370`; pomocnicze: `appliedMigrations(_:)` (`:503`), `hasSchemaChanges(_:)` (`:427`).
- Przepis wykonalny w czystym `swift test` pakietu, bez symulatora i bez binarnych fixture'ów: `migrate(db, upTo: "v11_classParticipation")` → INSERT danych → `migrate(db)` → asercje na przetrwaniu wierszy. Świadome ograniczenie: chroni przed rozjazdem zarejestrowanych migracji (jedyny wektor incydentu przy konwencji append-only); nie symuluje „stary binariusz pisze, nowy migruje".

### Mapowanie PREntryRecord (Risk #3)

- Zapis `init(from:updatedAt:)` (`AppDatabase/Sources/AppDatabase/Records/PREntryRecord.swift:124-160`): bezstratny, exhaustive switch po `PRScoreValue` (`:129-140`), `reps` reużywa kolumny `rounds` (`:134-136`), equipment → posortowany CSV rawValues (`:152`).
- Odczyt `toDomain()` (`:163-196`) — cztery stratne przejścia:
  1. `:164` — nieznany `scoreType` → `return nil` → **cały wpis znika**;
  2. `:168-178` — scoreType wskazuje grupę, kolumna NULL → `return nil` (dziś bez triggera: init gwarantuje parowanie);
  3. `:181` — nieznany rawValue sprzętu → cicho odfiltrowany (`compactMap`), wpis przeżywa okrojony;
  4. `:194` — nieznany kontekst → ciche przepisanie na `.fresh` (zafałszowanie).
- `toDomain()` zwraca nil **bez `reportIssue`** — nawet developer nie zobaczy znikających wierszy.

### Klient zapisu i połknięcie błędu w reducerze (Risk #3)

- `WorkoutMirrorLive/FeaturesNew/PRBoard/Client/PREntryClient.swift:44-68`: `database.write` + `upsert { draft }` — błędy propagują (nie połyka). Ale draft = **ręczna kopia 16 pól** (`:49-65`); nowa opcjonalna kolumna zapomniana w tej kopii skompiluje się i cicho zgubi pole (wzorzec „kompiluje się ≠ działa").
- `PREntryEditorFeature.swift:59-64`: `do { try await prEntryClient.save } catch { reportIssue(error) }` + **bezwarunkowy `await dismiss()`** — w RELEASE `reportIssue` to no-op → **nieudany zapis nieodróżnialny od sukcesu**. Analogicznie delete: `PRMovementDetailFeature.swift:36-40`.
- Editor tworzy dziś wyłącznie `.weight` (`PREntryEditorFeature.swift:35`) — ścieżki time/reps/amrap rekordu to martwy kod bez pokrycia runtime (ożyją w S-03).

### Ścieżka odczytu — niewidzialność defektów

- Trzy State'y czytają surowe rekordy przez `@FetchAll(PREntryRecord.all)` i dekodują `compactMap { $0.toDomain() }`: `PRBoardFeature+State.swift:30,37` (liczniki), `PRMovementListFeature+State.swift:32,50`, `PRMovementDetailFeature+State.swift:36,43-44`. Wiersz z defektem **jest w bazie, ale znika ze wszystkich list, liczników i wyliczenia PR** — bez sygnału.

### Precedens w innych rekordach

- `ExerciseLogRecord.swift:207` — `setsData: try? ... encode(...)` → błąd enkodowania = **strata przy zapisie** (per-set breakdown ginie, wiersz zapisuje się „sukcesem"); `:238` — `try? decode` → drift `SetEntry` = wszystkie historyczne serie cicho znikają; `:239` — `ScalingType(rawValue:) ?? .rx`.
- Kontr-wzorzec bezpieczny: `TrainingSessionRecord.swift:94,110` — mapowania `throws`, nieznane rawValues rzucają `TrainingSessionRecordError` (`:112-136`). Nic nie znika cicho.
- **Testy round-trip nie istnieją dla żadnego rekordu.**

### Infrastruktura testowa (stan zastany)

- Targety testowe: SharedModels (`Package.swift:29-32`), AppDatabase (`Package.swift:31-34`, deps tylko `["AppDatabase"]` — SQLiteData tranzytywnie); Commons/HealthHub/PeerMirror bez testów. App target: `WorkoutMirrorLiveTests` (jedyny unit-bundle w pbxproj, TEST_HOST = WorkoutMirrorLive.app).
- `MigratorTests.swift:18` to **jedyne in-memory DB w całym repo**; nigdzie nie przygotowuje się `@Dependency(\.defaultDatabase)` na in-memory poza produkcją (testy TCA nadpisują klientów przez `withDependencies` — `PREntryEditorFeatureTests.swift:31-44`; preview PersonSettings używa PRAWDZIWEJ bazy przez `try? bootstrapDatabase()`).
- Konsumenci `\.defaultDatabase` (liveValue klientów, żaden nie ma wstrzykiwalnej bazy): PREntryClient, TrainingSessionClient, UserProfileClient, ExerciseLogClient, WorkoutPlanScoreClient, ExerciseCatalogClient, ClassParticipationClient, EffortScoreClient, WorkoutHRSnapshotClient, GymClassClient.
- Pułapka nazewnicza: `StepTrackerTCA/**/​*Test.swift` (WeightGoalTest itd.) to legacy reducery, nie testy.

## Code References

- `AppDatabase/Sources/AppDatabase/Schema.swift:28-43` — bootstrapDatabase() z DEBUG erase
- `AppDatabase/Sources/AppDatabase/Schema.swift:48-50` — publiczny AppDatabaseSchema.makeMigrator()
- `AppDatabase/Sources/AppDatabase/Schema.swift:165-167` — ostrzeżenie append-only w kodzie
- `AppDatabase/Sources/AppDatabase/Schema.swift:358-386` — migracja v12_prEntries (STRICT, indeks na movementId, bez UNIQUE)
- `AppDatabase/Tests/AppDatabaseTests/MigratorTests.swift:16-28` — obecny (ślepy na dane) test migratora
- `AppDatabase/.build/checkouts/GRDB.swift/GRDB/Migration/DatabaseMigrator.swift:370,427-464,646-660` — migrate(upTo:), hasSchemaChanges, mechanizm erase
- `AppDatabase/Sources/AppDatabase/Records/PREntryRecord.swift:124-160` — bezstratny zapis
- `AppDatabase/Sources/AppDatabase/Records/PREntryRecord.swift:163-196` — 4 stratne przejścia odczytu
- `AppDatabase/Sources/AppDatabase/Records/ExerciseLogRecord.swift:207,238-239` — precedens aktywnej cichej straty (JSON blob try?)
- `AppDatabase/Sources/AppDatabase/Records/TrainingSessionRecord.swift:94-136` — kontr-wzorzec throws
- `WorkoutMirrorLive/FeaturesNew/PRBoard/Client/PREntryClient.swift:44-76` — save/delete, ręczna kopia 16 pól do Draft
- `WorkoutMirrorLive/FeaturesNew/PRBoard/Child/PREntryEditor/Feature/PREntryEditorFeature.swift:59-64` — catch+reportIssue+bezwarunkowy dismiss
- `WorkoutMirrorLive/FeaturesNew/PRBoard/Child/PRMovementDetail/Feature/PRMovementDetailFeature.swift:36-40` — analogiczne połknięcie przy delete
- `WorkoutMirrorLive/FeaturesNew/PRBoard/**/+State.swift` — compactMap(toDomain) w 3 State'ach (niewidzialność defektów)

## Architecture Insights

- **Filozofia „defensive nil" vs „loud failure"**: Records mają dwa konkurujące wzorce — PREntryRecord/ExerciseLogRecord (nil/`try?` = ciche znikanie) vs TrainingSessionRecord (throws + dedykowane błędy). Testy round-trip zamrożą kontrakt tam, gdzie zmiana filozofii byłaby droga.
- **`makeMigrator()` jako szew testowy**: wydzielony w S-02 dokładnie po to; rozszerzenie testów migratora nie wymaga ŻADNYCH zmian produkcyjnych.
- **Klienty poza pakietami**: warstwa `swift test` kończy się na rekord+SQL; kontrakt klient→Draft i zachowanie reducera przy błędzie zapisu są testowalne tylko z app targetu (TestStore) — lub pozostają świadomą luką.
- Drobna niespójność bez znaczenia funkcjonalnego: produkcja używa `DatabasePool` (plik), testy `DatabaseQueue` (in-memory).

## Historical Context (from prior changes)

- `context/archive/2026-08-31-record-entry-current-pr/plan.md:117,125` — decyzje schematu v12: kolumny płaskie bez BLOB (kontr-decyzja wobec setsData), bez UNIQUE (duplikaty by design), defensywny `toDomain() -> PREntry?`.
- `context/archive/2026-08-31-record-entry-current-pr/plan.md:47,153` — rytuał „świadoma decyzja o momencie builda na fizycznym urządzeniu dev" (incydent 2026-08-03).
- `context/archive/2026-08-31-record-entry-current-pr/plan.md:133,160-175` — wydzielenie makeMigrator() + decyzja o ręcznym struct PREntryClient (nie @DependencyClient), testValue unimplemented.
- `context/foundation/lessons.md` — reguły: append-only, „przy pierwszej okazji test migratora", fixture'y bez `.now`.

## Related Research

- `context/archive/2026-08-31-pr-board-entry-and-catalog/research.md` — badanie S-01 (katalog, toolbar).

## Open Questions

1. Czy test round-trip powinien od razu pokrywać wszystkie 4 typy wyniku (time/reps/amrap to dziś martwy kod — ożyje w S-03)? Rekomendacja: tak, bo testuje kontrakt rekordu, nie editor — i wyprzedza S-03.
2. Czy „zapis udaje sukces" w reducerze (catch+dismiss) naprawiać w tej fazie (zmiana produkcyjna — poza zakresem czysto testowej fazy), czy tylko odnotować jako kandydata na osobną zmianę? Do decyzji przy planie.
3. Czy dopisać `reportIssue` w `toDomain()` przy nil-collapse (DEBUG-owa telemetria znikających wierszy)? Jw. — zmiana produkcyjna, do decyzji przy planie.
