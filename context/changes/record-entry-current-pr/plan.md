# Tablica PR — zapis wpisu i wyznaczanie aktualnego PR (S-02): plan implementacji

## Przegląd

Gwiazda przewodnia roadmapy (US-01): użytkownik na szczególe ruchu dodaje wynik ciężarowy z metadanymi (data ≤ dziś, Rx/scaled gdzie wspierane, sprzęt multiselect, RPE 6–10 co 0.5, notatka; masa ciała dopisywana automatycznie jako snapshot), wpis trwale ląduje w nowej tabeli (migracja v12), a aktualny PR — wyliczany kompletną czystą funkcją z historii — pojawia się na szczególe, w wierszu listy i w liczniku kategorii. Funkcja PR powstaje OD RAZU dla wszystkich typów wyników i rozdziału Rx/scaled, z pełną suitą testów (kryterium PRD + wymóg certyfikacji); UI w S-02 obsługuje tylko ciężar.

## Analiza stanu obecnego

Pełny obraz: `context/changes/record-entry-current-pr/research.md`. Skrót nośny:

- Wzorzec migracji żelazny: `Schema.swift:310-336` (v11) — STRICT, `"id" TEXT NOT NULL PRIMARY KEY ON CONFLICT REPLACE`, ogony `createdAt`/`updatedAt`/`ckRecordData` (furtka `CloudKitSyncable.swift:19`), zero FOREIGN KEY, indeksy `index_<tabela>_on_<kolumna>`; v12 wchodzi po `:336`, przed `migrate` (`:338`). AppDatabase nie ma testTargetu.
- Wzorzec rekordu: `ClassParticipationRecord.swift` (szablon), enumy jako String rawValue, sekcja Mapping.
- Wzorzec klienta: `ExerciseLogClient.swift:16-114` (ręczny struct, liveValue IIFE, `database.write` + `upsert { Draft }`, testValue unimplemented).
- Refresh: precedens `@FetchAll` — `PersonalActivityFeature+State.swift:54-69` (`@ObservationStateIgnored @FetchAll(...)`).
- Masa ciała: `PersonalDataClient.getWeightForDate(Date) -> HealthKitData?` (kg), zero produkcyjnych użyć; wzorzec nieblokujący `(try? await ...) ?? nil`.
- Formularz: wzorzec draft+walidacja `ExerciseEditor` (isSaveDisabled w State, Save w toolbarze `.disabled`); wariant „dziecko samo persystuje": `PersonProfileEditFeature.swift:30-46`.
- RPE/sprzęt/picker Rx-scaled: brak w repo — budujemy od zera.
- Punkty wpięcia: `PRMovementDetailFeature.swift:15-24` (pusty Action, EmptyReducer — do rozbudowy + split na +State/+Action), licznik `"0/"` `PRBoardView.swift:89`, wartość wiersza `PRMovementListView.swift:91`, slot `actions:` pustego stanu (`PRMovementDetailView.swift:79-86`).
- sqlite-data: pin 1.6.x wystarcza (1.6→1.11.2 bez breaking changes) — bez upgrade'u.

## Pożądany stan końcowy

Pełny przepływ US-01 działa: Ćwiczenia → Tablica → Siła → Back Squat → „+" → formularz (kg, data, Rx/scaled jeśli wspierane, sprzęt, RPE, notatka) → zapis → szczegół pokazuje dużą wartość PR i listę wpisów, wiersz Back Squat w liście przestaje być „muted" i pokazuje PR, licznik Siły rośnie do 1/8 z datą. Wpis przeżywa restart aplikacji. `swift test` w obu pakietach zielony (SharedModels: testy funkcji PR; AppDatabase: test migratora v1→v12), oba w matrixie CI.

### Kluczowe odkrycia:

- Czysta funkcja i typy domenowe w SharedModels ⇒ testy jadą w CI bez zmian workflow (jedyny pakiet w matrixie; F2 dokłada drugi).
- `bootstrapDatabase()` (`Schema.swift:28`) buduje migrator inline — test migratora wymaga wydzielenia buildera (kontrakt w F2), bez zmiany zachowania bootstrapu.
- Kryterium akceptacji US-01: „PR wyliczony z historii — usunięcie wpisu cofa PR" ⇒ ZERO zdenormalizowanych wartości w bazie (guardrail FR-007).
- Guardrail wydajności PRD: liczniki/PR z pełnej historii nie blokują UI — `@FetchAll` filtruje w SQLite, agregacja w Swift na małych zbiorach (setki wpisów).

## Czego NIE robimy

- UI dla typów wyników time/reps/amrap (S-03) — funkcja i testy TAK, kontrolki NIE.
- Badge Rx/Scaled i porównanie benchmarków na szczególe (S-04) — pole `isRx` zapisujemy, prezentacja rozdziału przyjdzie w S-04.
- Usuwanie wpisów (S-05), wykres/krotność masy ciała/considered polish (S-06).
- Edycji wpisu (poza PRD w ogóle), estymat 1RM, konsumpcji mostków katalogu.
- Upgrade'u sqlite-data (osobny ticket; 1.6.x wystarcza).
- Blokady duplikatów dzień+ruch (dozwolone — decyzja użytkownika); soft-delete.

## Podejście do implementacji

Cztery atomowe fazy od środka na zewnątrz: (1) czysta domena + testy w SharedModels; (2) persystencja + test migratora w AppDatabase + CI; (3) klient zapisu i formularz (dziecko samo persystuje — wzorzec PersonProfileEdit, bo `@FetchAll` uwalnia od delegatów odświeżania); (4) ożywienie trzech ekranów przez `@FetchAll`. Reducery wyłącznie z kontrolowanymi zależnościami (`\.date.now`, `\.uuid`, kliency — lessons.md).

## Krytyczne szczegóły implementacji

- **Moment migracji na urządzeniu dev (lessons.md, incydent 03.08)**: DEBUG ma `eraseDatabaseOnSchemaChange = true` — pierwszy build fazy 2 na FIZYCZNYM urządzeniu deweloperskim skasuje lokalną bazę (plany, logi, wyniki). Symulator — bez znaczenia. Przed buildem na urządzeniu: świadoma decyzja/backup (kryterium ręczne 2.x).
- **Remis w funkcji PR**: „remis rozstrzyga nowsza data" — przy dozwolonych duplikatach dzień+ruch potrzebny drugi poziom rozstrzygnięcia: równa wartość i równa `date` → wygrywa późniejszy `createdAt`. Kontrakt funkcji musi to jawnie pokrywać (i test).
- **Snapshot masy ciała nie blokuje zapisu** (kryterium US-01): `(try? await personalDataClient.getWeightForDate(date))?.value` — nil przy braku zgody/danych; zapis idzie dalej.

## Faza 1: Domena PR i czysta funkcja z testami (SharedModels)

### Przegląd

Typy wpisu + kompletny resolver PR (wszystkie typy wyników, rozdział Rx/scaled, remisy) + pierwsza suita testów domenowych projektu.

### Wymagane zmiany:

#### 1. Typy domenowe

**Plik**: `SharedModels/Sources/SharedModels/SharedModels/PRCatalog/PREntry.swift` (nowy)

**Cel**: model pojedynczego wpisu wyniku — wejście czystej funkcji i lustro przyszłego rekordu DB.

**Kontrakt**:
- `public enum PRScoreValue: Codable, Sendable, Equatable` — `weight(kilograms: Double)`, `time(seconds: Int)`, `reps(count: Int)`, `amrap(rounds: Int, extraReps: Int)`; computed `scoreType: PRScoreType`.
- `public enum PREquipment: String, CaseIterable, Codable, Sendable` — `belt, kneeSleeves, wristWraps, straps, weightVest, chalk`; `displayName` (localized `.module`) + `sfSymbolName: String` (ikona na szczegół — US-01).
- `public enum PRContext: String, CaseIterable, Codable, Sendable` — `fresh, inWod, competition`; `displayName` localized; default domenowy `fresh`.
- `public struct PREntry: Identifiable, Codable, Sendable, Equatable` — `id: UUID`, `movementId: String`, `date: Date` (dzień wyniku), `createdAt: Date` (timestamp zapisu — tie-break), `score: PRScoreValue`, `isRx: Bool?` (nil = ruch bez Rx/scaled), `equipment: Set<PREquipment>`, `rpe: Double?`, `note: String?`, `bodyWeightKg: Double?`, `context: PRContext`.

#### 2. Czysta funkcja currentPR

**Plik**: `SharedModels/Sources/SharedModels/SharedModels/PRCatalog/PRResolver.swift` (nowy)

**Cel**: jedyne źródło prawdy wyznaczania PR (FR-007, Business Logic Changes PRD) — bez stanu, bez zależności, bez zapisu.

**Kontrakt**:
- `public enum PRResolver` (namespace).
- `public struct PRSummary: Equatable, Sendable` — `best: PREntry?`, `bestRx: PREntry?`, `bestScaled: PREntry?`.
- `public static func summary(for movement: PRMovement, entries: [PREntry]) -> PRSummary` — filtruje po `movementId`; dla `supportsRxScaled`: `bestRx`/`bestScaled` liczone OSOBNO (scaled nigdy nie bije Rx — brak wspólnego rankingu), `best` = `bestRx ?? bestScaled`; dla pozostałych: tylko `best`.
- `public static func isBetter(_ lhs: PREntry, than rhs: PREntry) -> Bool` (lub wewnętrzny komparator) — kierunek wg `scoreType`: weight/reps więcej=lepiej, time mniej=lepiej, amrap leksykograficznie (rounds, potem extraReps); remis wartości → późniejsza `date`; remis daty → późniejszy `createdAt`.
- Pomocnicze dla liczników: `public static func completedMovementIds(entries: [PREntry]) -> Set<String>` i `public static func latestEntryDate(entries: [PREntry]) -> Date?` (ekran kategorii: licznik + data ostatniego PR).

#### 3. Testy czystej funkcji

**Plik**: `SharedModels/Tests/SharedModelsTests/PRResolverTests.swift` (nowy)

**Cel**: jawne kryterium sukcesu PRD („poprawność dla wszystkich typów wyniku potwierdzona testami czystej funkcji") + wymóg certyfikacji.

**Kontrakt**: swift-testing (`@Suite`/`@Test`/`#expect` — wzorzec `ExerciseTypeMatchingTests`); fixture'y dat przez `Date(timeIntervalSince1970:)` (lessons.md — nigdy `.now`). Przypadki obowiązkowe: weight więcej=lepiej; time mniej=lepiej; reps; amrap leksykograficznie (6+0 bije 5+10); remis wartości → nowsza data; remis daty → nowszy createdAt (duplikaty tego samego dnia); rozdział Rx/scaled — lepszy czas scaled NIE bije Rx (scenariusz US-02: Fran 8:10 Rx vs 6:30 scaled); ruch bez wpisów → summary puste; wpisy innego ruchu ignorowane; `completedMovementIds`/`latestEntryDate`.

### Kryteria sukcesu:

#### Weryfikacja automatyczna:

- `swift build --package-path SharedModels` przechodzi
- `swift test --package-path SharedModels` — nowa suita PRResolver zielona, stare 38 bez regresji

**Uwaga implementacyjna**: faza czysto pakietowa — po zielonych testach stop na commit użytkownika.

---

## Faza 2: Migracja v12, rekord i test migratora (AppDatabase)

### Przegląd

Persystencja wpisów + pierwszy testTarget AppDatabase (health-check fix #4, lessons.md „przy pierwszej okazji") + drugi pakiet w matrixie CI.

### Wymagane zmiany:

#### 1. Rekord

**Plik**: `AppDatabase/Sources/AppDatabase/Records/PREntryRecord.swift` (nowy)

**Cel**: płaski rekord wpisu PR zgodny z furtką CloudKitSyncable.

**Kontrakt**: `@Table public struct PREntryRecord: Identifiable, CloudKitSyncable, Sendable` — kolumny płaskie (wzorzec ClassParticipationRecord): `id: UUID`, `movementId: String`, `date: Date`, `scoreType: String` (rawValue), `weightKg: Double?`, `timeSeconds: Int?`, `rounds: Int?`, `extraReps: Int?` (dokładnie jedna grupa wypełniona wg scoreType), `isRx: Bool?`, `equipment: String` (rawValues rozdzielone przecinkami, default `""` — płaskie kolumny, bez BLOB), `rpe: Double?`, `note: String?`, `bodyWeightKg: Double?`, `context: String` (rawValue), + `createdAt/updatedAt/ckRecordData`. Extension Mapping: `init(from: PREntry, createdAt:updatedAt:)` + `toDomain() -> PREntry?` (nieznany scoreType → nil, wzorzec defensywny jak `?? .rx` w ExerciseLogRecord).

#### 2. Migracja v12

**Plik**: `AppDatabase/Sources/AppDatabase/Schema.swift`

**Cel**: nowa tabela `prEntryRecords` — append-only, zero zmian w v1–v11.

**Kontrakt**: `migrator.registerMigration("v12_prEntries")` wpięte po bloku v11 (`:336`), przed `migrate` (`:338`); CREATE TABLE STRICT wg konwencji (typy: TEXT/REAL/INTEGER, nullable zgodnie z rekordem) + `CREATE INDEX "index_prEntryRecords_on_movementId"`; 2–3-liniowy komentarz-uzasadnienie nad migracją (wzorzec v11). Bez UNIQUE indeksów (duplikaty dzień+ruch dozwolone).

#### 3. Wydzielenie buildera migratora + testTarget

**Pliki**: `AppDatabase/Sources/AppDatabase/Schema.swift`, `AppDatabase/Package.swift`, `AppDatabase/Tests/AppDatabaseTests/MigratorTests.swift` (nowy)

**Cel**: test „migrator przechodzi v1→v12 na pustej bazie in-memory" (lessons.md) — wymaga dostępu do migratora poza `bootstrapDatabase()`.

**Kontrakt**: refaktor minimalny — `package`/`public static` funkcja budująca `DatabaseMigrator` ze WSZYSTKIMI rejestracjami (np. `AppDatabaseSchema.makeMigrator()`), `bootstrapDatabase()` ją woła (zachowanie bez zmian, w tym DEBUG erase pozostaje w bootstrap); `Package.swift`: `.testTarget(name: "AppDatabaseTests", dependencies: ["AppDatabase"])`; test swift-testing: in-memory `DatabaseQueue()` + `makeMigrator().migrate(...)` bez błędu + sanity: tabela `prEntryRecords` istnieje.

#### 4. CI matrix

**Plik**: `.github/workflows/ci.yml`

**Cel**: testy AppDatabase w CI (konstrukcja matrixa była na to gotowa od lekcji 1.5).

**Kontrakt**: `matrix.package: [SharedModels, AppDatabase]` — jedyna zmiana; cache per pakiet już parametryzowany.

### Kryteria sukcesu:

#### Weryfikacja automatyczna:

- `swift test --package-path AppDatabase` — test migratora v1→v12 zielony
- `swift test --package-path SharedModels` nadal zielone
- `grep -n "AppDatabase" .github/workflows/ci.yml` znajduje wpis w matrixie

#### Weryfikacja ręczna:

- Świadoma decyzja o momencie builda fazy 2 na fizycznym urządzeniu dev — DEBUG erase skasuje lokalną bazę (użytkownik)

**Uwaga implementacyjna**: stop na potwierdzenie i commit użytkownika.

---

## Faza 3: Klient zapisu i formularz wpisu

### Przegląd

`PREntryClient` + feature `PREntryEditor` (sheet ze szczegółu ruchu) — dziecko samo persystuje i dismissuje; odświeżenie ekranów załatwi `@FetchAll` (faza 4).

### Wymagane zmiany:

#### 1. Klient

**Plik**: `WorkoutMirrorLive/FeaturesNew/PRBoard/Client/PREntryClient.swift` (nowy)

**Cel**: granica zapisu wpisów (odczyty pójdą przez `@FetchAll` w State — klient w S-02 tylko zapisuje; S-05 dołoży delete).

**Kontrakt**: ręczny struct (wzorzec ExerciseLogClient — NIE `@DependencyClient`): `var save: @Sendable (PREntry) async throws -> Void`; liveValue IIFE z `@Dependency(\.defaultDatabase)` + `@Dependency(\.date.now)`; `database.write` + `PREntryRecord.upsert { Draft }`; `testValue` z `unimplemented`.

#### 2. Feature formularza

**Pliki**: `WorkoutMirrorLive/FeaturesNew/PRBoard/Child/PREntryEditor/Feature/PREntryEditorFeature.swift` (+ `+State.swift`, `+Action.swift`), `.../PREntryEditorView.swift` (nowe)

**Cel**: formularz „dodaj wynik" dla scoreType == .weight z walidacją i snapshotem masy ciała.

**Kontrakt**:
- State: `let movement: PRMovement`, draft: `weightText: String` (parsowanie jak SetTable — TextField `.decimalPad`), `date: Date` (init z parametru — rodzic poda `\.date.now`), `isRx: Bool` (widoczne tylko gdy `movement.supportsRxScaled`), `context: PRContext = .fresh` (FR-004; segmented picker 3 wartości), `equipment: Set<PREquipment>`, `rpe: Double?` (nil = brak; wartości 6.0–10.0 co 0.5), `note: String`; `var isSaveDisabled: Bool` — `Double(weightText)` nil lub ≤ 0 (wzorzec ExerciseEditorFeature+State.swift:51-56).
- Action: `ViewAction, BindableAction`; view: `saveTapped`, `cancelTapped`; wewnętrzne: `saveCompleted`.
- Reducer: deps `\.prEntryClient`, `\.personalDataClient`, `\.uuid`, `\.date.now`, `\.dismiss`; save = zbuduj `PREntry` (id z uuid, `createdAt` z date.now, `bodyWeightKg` = `(try? await getWeightForDate(state.date))?.value` — NIEblokująco) → `try await save` (błąd → `reportIssue`, wzorzec SummaryFeature:282-288) → `dismiss()`. Konwencje: `@CasePathable` na Action w extension + `some Reducer<State, Action>` (pułapka z S-01!).
- View: `NavigationStack { Form/ScrollView+GroupBox }` + toolbar Cancel/Save z `.disabled(store.isSaveDisabled)` (wzorzec ExerciseEditorView:57-65); pola: kg (TextField String, `.decimalPad`, sufiks „kg"), DatePicker `in: ...date.now` — górne ograniczenie przekazane w State (data ≤ dziś), segmented kontekstu (fresh/inWod/competition, default fresh), segmented Rx/Scaled (tylko `supportsRxScaled`), sprzęt jako multiselect (toggle-chipy z `sfSymbolName`), RPE `Picker(.menu)` z „—" + 6.0–10.0 co 0.5, notatka `TextField(axis: .vertical)`; View Facade, zero `@State`, `String(localized:)`.

#### 3. Wpięcie w szczegół ruchu

**Pliki**: `WorkoutMirrorLive/FeaturesNew/PRBoard/Child/PRMovementDetail/Feature/PRMovementDetailFeature.swift` (+ NOWE `+State.swift`, `+Action.swift` — split jak reszta feature'ów), `.../PRMovementDetailView.swift`

**Cel**: przycisk „+" (toolbar szczegółu) i akcja w pustym stanie (`ContentUnavailableView` slot `actions:`) otwierają edytor.

**Kontrakt**: State += `@Presents var editor: PREntryEditorFeature.State?`; Action = pełny `@CasePathable ViewAction` (`addEntryTapped`) + `editor(PresentationAction<...>)`; reducer: `Reduce` + `.ifLet` (koniec EmptyReducer); View: `@ViewAction` + `@Bindable`, `.toolbar` z przyciskiem plus, `.sheet(item:)` na edytor.

### Kryteria sukcesu:

#### Weryfikacja automatyczna:

- `ls WorkoutMirrorLive/FeaturesNew/PRBoard/Child/PREntryEditor/Feature` przechodzi
- `grep -r "@State" WorkoutMirrorLive/FeaturesNew/PRBoard/` zwraca 0 trafień
- `grep -rn "ReducerOf<Self>" WorkoutMirrorLive/FeaturesNew/PRBoard/` zwraca 0 trafień

#### Weryfikacja ręczna:

- Build `WorkoutMirrorLive` przechodzi (użytkownik)
- Formularz: zapis poprawnego kg działa, Save nieaktywny przy pustym/zerowym kg, data nie pozwala na przyszłość (użytkownik)

**Uwaga implementacyjna**: stop na potwierdzenie i commit użytkownika.

---

## Faza 4: Ożywienie ekranów przez @FetchAll

### Przegląd

Liczniki kategorii, wartości PR w wierszach i szczegół z listą wpisów — wszystko obserwuje bazę (`@FetchAll`), zero ręcznego refetchu.

### Wymagane zmiany:

#### 1. Ekran kategorii (liczniki + data ostatniego PR)

**Pliki**: `WorkoutMirrorLive/FeaturesNew/PRBoard/Feature/PRBoardFeature+State.swift`, `.../PRBoardView.swift`

**Cel**: licznik `N/M` per kategoria + względna data ostatniego PR zamiast „—" (US-01: licznik rośnie po zapisie).

**Kontrakt**: State += `@ObservationStateIgnored @FetchAll(PREntryRecord.all) var entryRecords` (wzorzec PersonalActivityFeature+State.swift:54-69) + computed: per kategoria liczba ruchów z ≥1 wpisem (mapowanie movementId→kategoria przez PRCatalog + `PRResolver.completedMovementIds`) i data ostatniego wpisu; `PRBoardView.swift:89` czyta z State zamiast literału `0/`, `lastRecordPlaceholder` → względna data (`Date.RelativeFormatStyle` lub „—").

#### 2. Lista ruchów (wartości PR, koniec mute)

**Pliki**: `.../PRMovementList/Feature/PRMovementListFeature+State.swift`, `.../PRMovementListView.swift`

**Cel**: wiersz ruchu z wpisami pokazuje aktualny PR (format wg scoreType) i pełny kolor; ruchy bez wpisów zostają „muted".

**Kontrakt**: State += `@ObservationStateIgnored @FetchAll` (wpisy; filtr per kategoria w computed przez PRCatalog) + computed `prLabel(for movement) -> String?` (przez `PRResolver.summary`); widok: wariant muted tylko gdy `prLabel == nil`.

#### 3. Szczegół ruchu (duża wartość PR + historia)

**Pliki**: `.../PRMovementDetail/Feature/PRMovementDetailFeature+State.swift`, `.../PRMovementDetailView.swift`

**Cel**: duża wartość aktualnego PR z datą + lista wpisów malejąco po dacie (data, wartość, ikony sprzętu, RPE, notatka); empty state znika po pierwszym wpisie.

**Kontrakt**: State += `@ObservationStateIgnored @FetchAll` inicjalizowany w `init` zapytaniem `PREntryRecord.where { $0.movementId.eq(movement.id) }` + computed `summary: PRSummary` (PRResolver); widok: karta hero z wartością PR (formatowanie weight: „150 kg", wzorzec formatWeight z SetTable), sekcja historii (GroupBox, wiersze: data krótka + wartość + `sfSymbolName` sprzętu + RPE); `ContentUnavailableView` tylko gdy brak wpisów.

### Kryteria sukcesu:

#### Weryfikacja automatyczna:

- `grep -rn "@FetchAll" WorkoutMirrorLive/FeaturesNew/PRBoard/` znajduje wpisy w 3 feature'ach
- `swift test --package-path SharedModels` i `swift test --package-path AppDatabase` zielone

#### Weryfikacja ręczna:

- Build `WorkoutMirrorLive` przechodzi (użytkownik)
- Pełny przepływ US-01: kategoria → ruch → wpis 150 kg → PR na szczególe z datą, wiersz listy pokazuje PR, licznik kategorii wzrósł; wpis przeżywa restart aplikacji (użytkownik)
- Drugi wpis lżejszy nie zmienia PR; cięższy zmienia (użytkownik)

**Uwaga implementacyjna**: ostatnia faza — po potwierdzeniu commit użytkownika + epilog.

---

## Strategia testowania

### Testy jednostkowe:

- PRResolver (SharedModels, F1): kierunki wszystkich typów, leksykografia AMRAP, remisy (data, createdAt), rozdział Rx/scaled (scaled nigdy nie bije Rx), zbiory pomocnicze.
- Migrator (AppDatabase, F2): v1→v12 na pustej bazie in-memory + istnienie tabeli.

### Kroki testowania ręcznego:

1. Pełny przepływ US-01 (faza 4, kryterium 4.4).
2. Walidacja formularza: pusty/zerowy kg blokuje Save; data ograniczona do dziś.
3. Snapshot masy ciała: wpis zapisuje się także przy braku zgody HealthKit (nieblokująco).

## Uwagi dotyczące migracji

v12 append-only, nowa tabela startuje pusta — brak migracji danych i planu wycofania (starszy kod ignoruje tabelę). DEBUG erase na urządzeniu dev: patrz Krytyczne szczegóły + kryterium 2.4.

## Referencje

- Badania: `context/changes/record-entry-current-pr/research.md`
- Wzorce: `Schema.swift:310-336`, `ClassParticipationRecord.swift`, `ExerciseLogClient.swift:16-114`, `PersonalActivityFeature+State.swift:54-69`, `ExerciseEditorView.swift:57-65`, `PersonProfileEditFeature.swift:30-46`
- Roadmapa S-02 + PRD FR-004/005/007/009/012, US-01, Business Logic Changes

## Postęp

> Konwencja: `- [ ]` oczekujące, `- [x]` wykonane. Dodaj ` — <commit sha>` po zakończeniu kroku. Nie zmieniaj tytułów kroków.

### Faza 1: Domena PR i czysta funkcja z testami (SharedModels)

#### Automatyczne

- [x] 1.1 `swift build --package-path SharedModels` przechodzi
- [x] 1.2 `swift test --package-path SharedModels` — nowa suita PRResolver zielona, stare 38 bez regresji

### Faza 2: Migracja v12, rekord i test migratora (AppDatabase)

#### Automatyczne

- [ ] 2.1 `swift test --package-path AppDatabase` — test migratora v1→v12 zielony
- [ ] 2.2 `swift test --package-path SharedModels` nadal zielone
- [ ] 2.3 `grep -n "AppDatabase" .github/workflows/ci.yml` znajduje wpis w matrixie

#### Ręczne

- [ ] 2.4 Świadoma decyzja o momencie builda fazy 2 na fizycznym urządzeniu dev — DEBUG erase skasuje lokalną bazę (użytkownik)

### Faza 3: Klient zapisu i formularz wpisu

#### Automatyczne

- [ ] 3.1 `ls WorkoutMirrorLive/FeaturesNew/PRBoard/Child/PREntryEditor/Feature` przechodzi
- [ ] 3.2 `grep -r "@State" WorkoutMirrorLive/FeaturesNew/PRBoard/` zwraca 0 trafień
- [ ] 3.3 `grep -rn "ReducerOf<Self>" WorkoutMirrorLive/FeaturesNew/PRBoard/` zwraca 0 trafień

#### Ręczne

- [ ] 3.4 Build `WorkoutMirrorLive` przechodzi (użytkownik)
- [ ] 3.5 Formularz: zapis poprawnego kg działa, Save nieaktywny przy pustym/zerowym kg, data nie pozwala na przyszłość (użytkownik)

### Faza 4: Ożywienie ekranów przez @FetchAll

#### Automatyczne

- [ ] 4.1 `grep -rn "@FetchAll" WorkoutMirrorLive/FeaturesNew/PRBoard/` znajduje wpisy w 3 feature'ach
- [ ] 4.2 `swift test --package-path SharedModels` i `swift test --package-path AppDatabase` zielone

#### Ręczne

- [ ] 4.3 Build `WorkoutMirrorLive` przechodzi (użytkownik)
- [ ] 4.4 Pełny przepływ US-01: kategoria → ruch → wpis 150 kg → PR na szczególe z datą, wiersz listy pokazuje PR, licznik kategorii wzrósł; wpis przeżywa restart aplikacji (użytkownik)
- [ ] 4.5 Drugi wpis lżejszy nie zmienia PR; cięższy zmienia (użytkownik)
