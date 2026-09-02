# Plan implementacji: Siatka bezpieczeństwa bazy (test-plan §3 Faza 1)

## Przegląd

Testy integracyjne in-memory w pakiecie AppDatabase dowodzące, że (a) migracje nie niszczą danych istniejącej bazy i (b) każdy rekord przeżywa round-trip zapis→odczyt bez cichych strat — plus naprawa dwóch znalezionych produkcyjnych cichych strat: reducer editora połykający błąd zapisu i `toDomain()` bez telemetrii przy nil-collapse. Realizuje ryzyka #2 i #3 z `context/foundation/test-plan.md`.

## Analiza stanu obecnego

Z `context/changes/testing-database-safety-net/research.md` (ugruntowane 2026-09-02, commit 70f8e97):

- `MigratorTests.swift:16-28` — jedyny test bazy: pusta in-memory `DatabaseQueue()` + pełna migracja + istnienie tabeli `prEntryRecords`. **Strukturalnie ślepy** na scenariusz incydentu 2026-08-03 (erase odpala się tylko na bazie z zastosowanymi migracjami).
- `AppDatabaseSchema.makeMigrator()` (`Schema.swift:48-50`) publiczny; GRDB 7.10.0 daje `migrate(_:upTo:)`, `appliedMigrations(_:)`, `hasSchemaChanges(_:)` — fixture „baza v11 z danymi" wykonalny bez zmian produkcyjnych.
- `PREntryRecord.toDomain()` (`:163-196`) — 4 stratne przejścia (nil-collapse wpisu, odfiltrowanie sprzętu, kontekst → `.fresh`), zero telemetrii; `compactMap` w 3 State'ach PRBoard czyni defekty niewidzialnymi.
- `PREntryEditorFeature.swift:59-64` — `catch { reportIssue(error) }` + bezwarunkowy `dismiss()` → nieudany zapis nieodróżnialny od sukcesu w RELEASE.
- `ExerciseLogRecord.swift:207,238` — podwójne `try?` na JSON blob `setsData`: strata możliwa już przy zapisie i przy każdym drifcie `SetEntry`.
- Kontr-wzorzec: `TrainingSessionRecord.swift:94-136` — mapowania `throws` z dedykowanymi błędami.
- 11 rekordów w `AppDatabase/Sources/AppDatabase/Records/`: AthleteSession, ClassParticipation, ClassSession, ExerciseLog, GymClass, PREntry, TrainingSession, UserProfile, WorkoutEffortScore, WorkoutHRSnapshot, WorkoutPlanScore.

## Pożądany stan końcowy

- `swift test --package-path AppDatabase` dowodzi: dane przeżywają migrację v11→v12; predykat DEBUG erase (`hasSchemaChanges`) jest false dla zsynchronizowanego kodu; każdy z 11 rekordów ma test round-trip; stratne przejścia odczytu są udokumentowane testami.
- Błąd zapisu wpisu PR jest widoczny dla użytkownika (alert, sheet zostaje otwarty), a nil-collapse w odczycie zostawia ślad `reportIssue` dla developera.
- `context/foundation/test-plan.md` §6.2 wypełnione wzorcem „jak dodać test integracyjny bazy".

Weryfikacja: kryteria sukcesu per faza (sekcja Postęp).

### Kluczowe odkrycia:

- Fixture v11: `makeMigrator().migrate(db, upTo: "v11_classParticipation")` → INSERT → `migrate(db)` — bez binarnych fixture'ów (research.md, GRDB `DatabaseMigrator.swift:370`)
- `hasSchemaChanges == false` testuje dokładnie predykat decydujący o DEBUG erase (`DatabaseMigrator.swift:646-660`)
- Wzorzec testu: `MigratorTests.swift:18-19` (in-memory `DatabaseQueue()`); fixture'y dat z `Date(timeIntervalSince1970:)` (lessons.md)
- Granica pakietu: round-trip w pakiecie = rekord+SQL; reducer/klient testowalne tylko z `WorkoutMirrorLiveTests` (TestStore, Cmd+U)

## Czego NIE robimy

- Żadnych nowych migracji ani zmian schematu (testy in-memory; zero ryzyka dla danych urządzenia dev — reguła lessons o momencie migracji nie aktywuje się)
- Żadnych zmian zachowania `toDomain()` — defensive nil ZOSTAJE (dodajemy tylko telemetrię `reportIssue`); zmiana filozofii na `throws` = osobna zmiana
- Bez testów pozostałych reducerów/przepływów TCA (faza twórcza — test-plan §7) poza jednym testem ścieżki błędu zapisu editora
- Bez zmian w CI (matrix już obejmuje AppDatabase)
- Bez naprawy analogicznego połknięcia przy delete (`PRMovementDetailFeature.swift:36-40`) — odnotowane, osobny kandydat (delete ma mniejszą stawkę: brak danych do stracenia)

## Podejście do implementacji

Koszt × sygnał: najpierw najtańsza warstwa chroniąca największą stawkę (migrator z danymi — pakiet, czysty `swift test`), potem kontrakt rekordów od najważniejszego (PREntry — moduł certyfikacyjny) przez najbardziej zagrożony (ExerciseLog) po resztę, na końcu zmiany produkcyjne wymagające builda aplikacji i Cmd+U. Wszystkie komentarze w kodzie po angielsku (house style); oczekiwane wartości w asercjach jako literały w fixture'ach — nigdy wyliczane kodem produkcyjnym (anty-wzorzec wyroczni).

## Krytyczne szczegóły implementacji

- **Kolejność faz 2→4 (reportIssue vs testy defensywne)**: testy defensywnych przejść z Fazy 2 przechodzą przez ścieżki, w które Faza 4 doda `reportIssue`. W Swift Testing zgłoszony issue = fail testu — Faza 4 MUSI zaktualizować te testy o `withKnownIssue` w tym samym commicie, w którym dodaje telemetrię.
- **Fixture v11 przez surowy SQL**: struktury `@Table` mapują NAJNOWSZY schemat — INSERT-y fixture'a v11 wykonywać `db.execute(sql:)` z jawnymi kolumnami wziętymi z treści migracji w `Schema.swift` (nie przez Draft).
- **IssueReporting w pakiecie**: `reportIssue` w `Records/` może wymagać jawnej zależności produktu IssueReporting w `AppDatabase/Package.swift` (dziś dostępne co najwyżej tranzytywnie przez SQLiteData) — dodać jawnie, jeśli import nie przechodzi.

## Faza 1: Migrator z danymi

### Przegląd

Rozszerzenie `MigratorTests` o scenariusz incydentu: baza v11 z danymi przeżywa migrację do v12; predykat erase jest false; wszystkie 11 tabel istnieje.

### Wymagane zmiany:

#### 1. Testy migratora

**Plik**: `AppDatabase/Tests/AppDatabaseTests/MigratorTests.swift`

**Cel**: trzy nowe testy obok istniejącego: (1) „dane przeżywają migrację" — `migrate(upTo: "v11_classParticipation")`, INSERT wierszy surowym SQL do ~4 reprezentatywnych tabel (profil, sesja treningowa, log serii, wynik planu), pełna `migrate(db)`, asercje na NIEZMIENIONE wartości wierszy (nie tylko count); (2) „hasSchemaChanges == false po pełnej migracji" — łapie każdą edycję historycznej migracji (predykat DEBUG erase); (3) „wszystkie tabele obecne" — 11 nazw tabel z `sqlite_master` (dziś sprawdzana tylko `prEntryRecords`).

**Kontrakt**: nazwy tabel/kolumn brane z treści migracji w `Schema.swift`; daty pełnosekundowe; asercje porównują wartości kolumn po migracji z literałami fixture'a. Anty-wzorzec unikany: asercja „nie rzuca" bez sprawdzenia wierszy.

### Kryteria sukcesu:

#### Automatyczna weryfikacja:

- `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test --package-path AppDatabase` zielony (4 testy migratora)

#### Ręczna weryfikacja:

(brak — faza czysto pakietowa)

---

## Faza 2: Round-trip PREntryRecord

### Przegląd

Kontrakt rekordu PR: każdy typ wyniku przeżywa zapis→odczyt bez strat; stratne przejścia odczytu udokumentowane.

### Wymagane zmiany:

#### 1. Testy round-trip PREntry

**Plik**: `AppDatabase/Tests/AppDatabaseTests/PREntryRecordRoundTripTests.swift` (nowy)

**Cel**: (1) round-trip dla KAŻDEGO `PRScoreValue` (weight/time/reps/amrap): `PREntry` → `PREntryRecord(from:updatedAt:)` → upsert do zmigrowanej in-memory bazy → fetch → `toDomain()` → równość WSZYSTKICH pól domenowych (nie samych id), w tym sprzęt wieloelementowy (CSV sortowane), RPE, notatka, kontekst, bodyWeight, isRx; (2) testy dokumentujące defensive-nil: wiersz z nieznanym `scoreType` (surowy SQL) → `toDomain() == nil`; nieznany token sprzętu → odfiltrowany, wpis przeżywa; nieznany kontekst → `.fresh`. Regresja łapana: rename rawValue w `PRScoreType`/`PREquipment`/`PRContext` natychmiast failuje z czytelną nazwą testu (research: główny realny trigger straty).

**Kontrakt**: oczekiwane wartości jako literały; `reps` fizycznie w kolumnie `rounds` — round-trip musi to pokryć asercją wartości domenowej (nie kolumny). Źródło: research.md „Mapowanie PREntryRecord".

### Kryteria sukcesu:

#### Automatyczna weryfikacja:

- `swift test --package-path AppDatabase` zielony (round-trip 4 typów + 3 testy defensywne)

#### Ręczna weryfikacja:

(brak)

---

## Faza 3: Round-trip pozostałych rekordów

### Przegląd

Siatka kontraktu dla pozostałych 10 rekordów; szczególna uwaga: ExerciseLogRecord (JSON blob) i TrainingSessionRecord (kontrakt throws).

### Wymagane zmiany:

#### 1. Testy round-trip rekordów

**Plik**: `AppDatabase/Tests/AppDatabaseTests/RecordRoundTripTests.swift` (nowy; jeśli urośnie nieczytelnie — dopuszczalny podział per rekord)

**Cel**: po jednym round-tripie dla: AthleteSession, ClassParticipation, ClassSession, GymClass, UserProfile, WorkoutEffortScore, WorkoutHRSnapshot, WorkoutPlanScore (fixture z wypełnionymi WSZYSTKIMI polami opcjonalnymi — puste pola nie wykrywają strat). Dla **ExerciseLogRecord** dodatkowo: round-trip z niepustym `sets` (dekodowany breakdown równy literałom) — dokumentuje dzisiejszy kontrakt `setsData` zanim cokolwiek go zdriftuje. Dla **TrainingSessionRecord**: test kontraktu throws — nieznany rawValue rzuca dedykowany `TrainingSessionRecordError` (nie nil, nie cisza).

**Kontrakt**: mapowania brane z istniejących API każdego rekordu (`init(from:)`/`toDomain()` lub odpowiedniki — implementator odczytuje z plików w `Records/`); wszystkie fixture'y z datami pełnosekundowymi. Anty-wzorce unikane: mockowanie bazy, porównywanie samych id, puste opcjonale.

### Kryteria sukcesu:

#### Automatyczna weryfikacja:

- `swift test --package-path AppDatabase` zielony (komplet: migrator + 11 rekordów)

#### Ręczna weryfikacja:

(brak)

---

## Faza 4: Fixy produkcyjne + test przepływu błędu + cookbook

### Przegląd

Dwie naprawy cichych strat (decyzja usera: „naprawiamy od razu") + test przepływu błędu zapisu + wypełnienie §6 test-planu.

### Wymagane zmiany:

#### 1. Telemetria nil-collapse w odczycie

**Plik**: `AppDatabase/Sources/AppDatabase/Records/PREntryRecord.swift`, `AppDatabase/Sources/AppDatabase/Records/ExerciseLogRecord.swift` (+ ew. `AppDatabase/Package.swift` — jawna zależność IssueReporting)

**Cel**: każde stratne przejście (`toDomain()` → nil w PREntryRecord; `try?` dekodowania `setsData` w ExerciseLogRecord) zgłasza `reportIssue` z id rekordu i powodem — zachowanie (nil/filtr) BEZ ZMIAN, tylko sygnał dla developera. Testy defensywne z Fazy 2 owinięte `withKnownIssue` W TYM SAMYM commicie.

**Kontrakt**: `reportIssue("...: \(id)")` przed każdym `return nil`/`compactMap`-stratą; komunikaty po angielsku.

#### 2. Błąd zapisu widoczny dla użytkownika

**Plik**: `WorkoutMirrorLive/FeaturesNew/PRBoard/Child/PREntryEditor/Feature/PREntryEditorFeature.swift` (+ `+State`/`+Action` wg układu feature'a), `.../PREntryEditor/PREntryEditorView.swift`

**Cel**: w `catch` zapisu — zamiast bezwarunkowego `dismiss()` — sheet zostaje otwarty i pojawia się alert („Nie udało się zapisać wpisu" + OK; klucz w String Catalog, PL wartość). `dismiss()` wykonuje się wyłącznie po udanym zapisie. `reportIssue(error)` zostaje.

**Kontrakt**: `@Presents var alert: AlertState<Action.Alert>?` + case `alert(PresentationAction<Alert>)` (wzorzec `@CasePathable` jawnie na Action w extension; `some Reducer<State, Action>`); View: `.alert($store.scope(...))`. Doc /// dla nowych property/case (konwencja repo).

#### 3. Test przepływu błędu zapisu

**Plik**: `WorkoutMirrorLiveTests/PREntryEditorFeatureTests.swift`

**Cel**: nowy test TestStore: `prEntryClient.save` rzuca → stan dostaje alert, `dismiss` NIE został wywołany; istniejące 2 testy bez regresu (happy path nadal dismissuje). Wzorce: `withDependencies`, `LockIsolated` jako spy na DismissEffect.

**Kontrakt**: fixture'y dat `Date(timeIntervalSince1970:)`; test w Swift Testing jak istniejące.

#### 4. Cookbook §6 test-planu

**Plik**: `context/foundation/test-plan.md`

**Cel**: wypełnić §6.2 (lokalizacja `AppDatabase/Tests/AppDatabaseTests/`, wzorzec in-memory + makeMigrator, referencyjne testy z Faz 1–2, komenda `swift test` z DEVELOPER_DIR); dopisać notkę §6.6 o zaskoczeniach fazy (np. withKnownIssue przy telemetrii).

**Kontrakt**: tylko sekcje §6.2/§6.6 — §1–§5 zamrożone (edycje statusów §3 robi orkiestrator).

### Kryteria sukcesu:

#### Automatyczna weryfikacja:

- `swift test --package-path AppDatabase` zielony (testy defensywne zaktualizowane o withKnownIssue)
- §6.2 test-planu nie zawiera już „TBD — see §3 Phase 1"

#### Ręczna weryfikacja:

- Build aplikacji w Xcode przechodzi (buduje użytkownik — house rule)
- Cmd+U: WorkoutMirrorLiveTests zielone (3 testy, w tym nowy test błędu zapisu)
- Wizualnie (opcjonalnie): wymuszony błąd zapisu (chwilowy throw w liveValue) pokazuje alert i nie zamyka formularza

---

## Strategia testowania

### Testy jednostkowe/integracyjne (pakiet):

- Migrator: dane przeżywają, predykat erase, komplet tabel
- Round-trip 11 rekordów; przypadki brzegowe: nieznane rawValues, wieloelementowy sprzęt, niepuste `sets`, wszystkie pola opcjonalne wypełnione

### Testy przepływów (app target, Cmd+U):

- Editor: błąd zapisu → alert, brak dismiss; happy path bez regresu

### Kroki testowania ręcznego:

1. Build + Cmd+U w Xcode
2. (opcjonalnie) chwilowy throw w `PREntryClient.liveValue.save` → alert widoczny, sheet otwarty, po usunięciu throw zapis działa

## Uwagi dotyczące wydajności

Brak wpływu — testy in-memory; `reportIssue` w RELEASE jest no-opem; alert leniwy.

## Uwagi dotyczące migracji

Żadna migracja nie jest dodawana ani zmieniana — zero ryzyka dla danych urządzenia dev (reguła lessons o momencie wdrożenia migracji nie aktywuje się).

## Referencje

- Badania: `context/changes/testing-database-safety-net/research.md`
- Umowa jakościowa: `context/foundation/test-plan.md` (§2 ryzyka #2/#3, §3 Faza 1)
- Wzorce testów: `AppDatabase/Tests/AppDatabaseTests/MigratorTests.swift`, `WorkoutMirrorLiveTests/PREntryEditorFeatureTests.swift`, `SharedModels/Tests/SharedModelsTests/PRResolverTests.swift`
- Konwencja commitów usera w kursie: `lesson3.1 (pK)` — przy rytuale commitów zaproponować w tej konwencji

## Postęp

> Konwencja: `- [ ]` oczekujące, `- [x]` wykonane. Dodaj ` — <commit sha>` po zakończeniu kroku. Nie zmieniaj tytułów kroków.

### Faza 1: Migrator z danymi

#### Automatyczne

- [x] 1.1 swift test AppDatabase zielony (4 testy migratora: dane przeżywają, hasSchemaChanges, komplet tabel)

### Faza 2: Round-trip PREntryRecord

#### Automatyczne

- [ ] 2.1 swift test AppDatabase zielony (round-trip 4 typów wyniku + 3 testy defensywne)

### Faza 3: Round-trip pozostałych rekordów

#### Automatyczne

- [ ] 3.1 swift test AppDatabase zielony (komplet: migrator + 11 rekordów, kontrakt throws TrainingSession)

### Faza 4: Fixy produkcyjne + test przepływu błędu + cookbook

#### Automatyczne

- [ ] 4.1 swift test AppDatabase zielony (testy defensywne z withKnownIssue)
- [ ] 4.2 §6.2 test-planu wypełnione (brak „TBD — see §3 Phase 1")

#### Ręczne

- [ ] 4.3 Build aplikacji w Xcode przechodzi
- [ ] 4.4 Cmd+U: WorkoutMirrorLiveTests zielone (w tym test błędu zapisu)
