# Tablica PR — wejście i katalog ruchów (S-01): plan implementacji

## Przegląd

S-01 z roadmapy `pr-board-mvp`: użytkownik otwiera Tablicę PR przyciskiem w toolbarze segmentu Ćwiczenia (fullScreenCover z zoom transition; globalne crown/AI/profil ukryte tylko w tym segmencie) i przegląda statyczny katalog 29 ruchów w 5 kategoriach z podgrupami; ruchy bez wpisów wyszarzone wariantem „muted", ale klikalne — pusty szczegół z notą standardu Rx dla benchmarków. Zero zmian w bazie danych i w istniejących mechanizmach (mostki katalogu uśpione).

## Analiza stanu obecnego

Pełny obraz: `context/changes/pr-board-entry-and-catalog/research.md`. Skrót nośny:

- Toolbar StatsTab zadeklarowany raz nad switchem segmentów (`StatsView.swift:52-54`, builder `:72-91`); zero warunków per-segment dziś; wybrany segment w `StatsFeature.State.context` (`+State.swift:39`).
- `StatsFeature.Destination` ma 2 case'y (`+Destination.swift:13-22`); wzorzec przycisk→akcja→destination→`fullScreenCover`+zoom gotowy do skopiowania (`StatsView.swift:60-64,87-90`, `StatsFeature.swift:148-150`).
- `MovementCategory` NIE pokrywa 5 kategorii Tablicy (brak Benchmarków) — katalog PR dostaje własny enum; wzorzec danych: `WorkoutVocabulary.swift` (single source of truth + publiczne API), NIE 600-liniowe równoległe switche ExerciseType.
- `wodAliases` nie istnieje w kodzie — mostki będą faktycznie uśpione. Mostek typowany celuje w istniejące case'y `ExerciseType` (bez żadnych zmian w v6 — constraint PRD).
- Styl StatsTab: `ScrollView + VStack(spacing: 12)` + `GroupBox` z labelem (caption+Divider) + `.styledGroupBox()`; puste stany `ContentUnavailableView`; wariant „muted" kolorem/wagą (wzorzec `UI/Summary/ExerciseList.swift:20,84-85`), NIE `.disabled`.

## Pożądany stan końcowy

Z segmentu Ćwiczenia można otworzyć pełnoekranową Tablicę PR: ekran kategorii (5 kart z licznikami uzupełnienia 0/N — wpisy nie istnieją do S-02), lista ruchów w podgrupach (wszystkie wyszarzone „muted", klikalne), pusty szczegół ruchu (nazwa, kategoria, nota Rx dla benchmarku, `ContentUnavailableView` „brak wpisów"). Segmenty Dziś/Analityka i ich toolbar bez zmian; przełączanie segmentów bez migotania. Weryfikacja: build + przejście pełnej ścieżki + testy pakietów zielone.

### Kluczowe odkrycia:

- Precedens warunkowego ToolbarItem: `ExerciseDetailView.swift:68-76`.
- Zoom transition wymaga `.matchedTransitionSource` na `ToolbarItem` (nie na Buttonie) — `StatsView.swift:90`.
- SharedModels lokalizuje przez `bundle: .module` + `Resources/Localizable.xcstrings` (wzorzec `MovementCategory.swift:12`).
- Hierarchia push wewnątrz własnego `NavigationStack` przez `.navigationDestination(item: $store.scope(...))` — wzorzec `PersonSettingsView.swift:39-53`; zakaz `StackState` (CLAUDE.md).

## Czego NIE robimy

- Żadnej persystencji ani migracji bazy (wpisy PR = S-02); liczniki kategorii pokazują 0.
- Żadnych zmian w `ExerciseType` (v6), `MovementCategory`, skanie AI, analityce — mostki katalogu są danymi, nic ich nie czyta.
- Bez testów jednostkowych katalogu (reguła repo: bez proaktywnych testów; testy czystej funkcji PR wejdą w S-02 zgodnie ze spec).
- Bez formularza wpisu, bez wykresów, bez usuwania (S-02/S-03/S-05/S-06).
- Bez tłumaczenia nazw ruchów i not Rx (EN — konwencja fitness); lokalizowane tylko nazwy kategorii/podgrup i teksty UI.
- Bez zmian w segmentach Dziś/Analityka.

## Podejście do implementacji

Trzy atomowe fazy: (1) katalog jako czyste dane w SharedModels — kompiluje się i testuje bez UI; (2) kompletny feature Tablicy w izolacji (previews); (3) minimalne wpięcie w StatsTab — jedyna modyfikacja istniejącego kodu wydzielona do osobnego commita (czysty revert, skupiony review FR-010/011). Konwencje: TCA 1.26 (`@Reducer`, `@ObservableState`, `@ViewAction`, `@Presents`), zero `@State` w View, View Facade, buttony w `private var`, `String(localized:)`.

## Krytyczne szczegóły implementacji

- **Toolbar bez migotania**: warunek `store.context == .exercises` realizować WEWNĄTRZ istniejącego `toolbarButton` (if/else na zestawach `ToolbarItem`), nie przez drugi modifier `.toolbar` — dwie deklaracje toolbara na różnych poziomach hierarchii to prosta droga do migotania. Przełączenie segmentu zmienia liczbę itemów — zachowanie animacji zweryfikować ręcznie (kryterium 3.x).
- **Mostki**: `exerciseType` wypełniać tylko, gdy odpowiedni case istnieje w `ExerciseType` v6 (weryfikacja nazw case'ów w trakcie implementacji; brak dopasowania → `nil`, NIE dodawać case'ów/aliasów do ExerciseType).
- **Lokalizacja kluczy z SharedModels**: nowe klucze działają od razu (source language EN); polskie tłumaczenia w `SharedModels/Sources/SharedModels/Resources/Localizable.xcstrings` dodaje użytkownik przez Xcode UI (reguła repo: nie edytować xcstrings ręcznie jako JSON) — ujęte jako krok ręczny fazy 1.

## Faza 1: Katalog ruchów w SharedModels

### Przegląd

Czyste dane: typy katalogu + rdzeń 29 ruchów z uśpionymi mostkami. Zero UI.

### Wymagane zmiany:

#### 1. Kategoria katalogu

**Plik**: `SharedModels/Sources/SharedModels/SharedEnum/PRCategory/PRCategory.swift` (nowy)

**Cel**: 5 stałych kategorii Tablicy PR — własny enum, bo `MovementCategory` nie pokrywa domeny (brak Benchmarków).

**Kontrakt**: `public enum PRCategory: String, CaseIterable, Codable, Sendable` — case'y `olympic, strength, gymnastics, conditioning, benchmarks`; `displayName` przez `String(localized:, bundle: .module)` (PL/EN); `color: Color` (wzorzec `MovementCategory.swift`).

#### 2. Typy wpisu katalogu

**Plik**: `SharedModels/Sources/SharedModels/SharedModels/PRCatalog/PRMovement.swift` (nowy)

**Cel**: model pojedynczego ruchu z metadanymi potrzebnymi w S-01 (prezentacja) i S-02 (typ wyniku, Rx/scaled) oraz uśpionymi mostkami.

**Kontrakt**:
- `public enum PRScoreType: String, Codable, Sendable` — `weight, time, reps, amrap` (steruje kontrolką w S-02 i kierunkiem PR).
- `public enum PRSubgroup: String, Codable, Sendable, CaseIterable` — płaski enum podgrup (`snatchFamily, cleanFamily, squats, pulls, presses, barGymnastics, handstand, rowing, running, cycling, girls, heroes`), `displayName` lokalizowany `bundle: .module`.
- `public struct PRMovement: Identifiable, Codable, Sendable, Equatable` — pola: `id: String` (stabilny, kebab-case), `name: String` (EN, nielokalizowane), `category: PRCategory`, `subgroup: PRSubgroup`, `scoreType: PRScoreType`, `supportsRxScaled: Bool`, `rxStandard: String?` (nota standardu — tylko benchmarki), `exerciseType: ExerciseType?` (mostek, uśpiony), `wodAliases: [String]` (mostek, uśpiony, default `[]`).

#### 3. Statyczne dane rdzenia

**Plik**: `SharedModels/Sources/SharedModels/SharedModels/PRCatalog/PRCatalog.swift` (nowy)

**Cel**: single source of truth katalogu (wzorzec `WorkoutVocabulary`), rdzeń 29 ruchów wg listy poniżej.

**Kontrakt**: `public enum PRCatalog` (namespace) — `public static let movements: [PRMovement]`, `public static func movements(in category: PRCategory) -> [PRMovement]` (pogrupowane wg podgrup, stabilna kolejność deklaracji), `public static func movement(id: String) -> PRMovement?`.

**Rdzeń katalogu (29 ruchów) — do zatwierdzenia/przycięcia przy przeglądzie planu:**

| Kategoria | Podgrupa | Ruchy | Typ wyniku |
|---|---|---|---|
| Olimpijskie | Rwanie | Snatch, Power Snatch | weight |
| Olimpijskie | Zarzut i podrzut | Clean & Jerk, Clean, Power Clean | weight |
| Siła | Przysiady | Back Squat, Front Squat, Overhead Squat | weight |
| Siła | Ciągi | Deadlift, Sumo Deadlift | weight |
| Siła | Wyciskania | Strict Press, Push Press, Bench Press | weight |
| Gimnastyka | Drążek i kółka | Pull-up, Chest-to-Bar Pull-up, Toes-to-Bar, Muscle-up | reps |
| Gimnastyka | Stanie na rękach | Handstand Push-up | reps |
| Kondycja | Wiosło | Row 500 m, Row 2000 m | time |
| Kondycja | Bieg | Run 1 km, Run 5 km | time |
| Kondycja | Rower | Bike Erg 1000 m | time |
| Benchmarki | The Girls | Fran, Grace, Helen, Diane, Cindy (amrap) | time / Cindy: amrap |
| Benchmarki | Hero WODs | Murph | time |

Benchmarki: `supportsRxScaled = true` + `rxStandard` (np. Fran: "21-15-9 · thrusters 42.5/30 kg · pull-ups"), `wodAliases` (np. `["fran"]`); pozostałe kategorie `supportsRxScaled = false`, `rxStandard = nil`. Mostki `exerciseType` tam, gdzie case istnieje w v6.

### Kryteria sukcesu:

#### Weryfikacja automatyczna:

- `swift build --package-path SharedModels` przechodzi
- `swift test --package-path SharedModels` — istniejące testy zielone (bez nowych)

#### Weryfikacja ręczna:

- Polskie tłumaczenia kluczy kategorii/podgrup dodane w Xcode (użytkownik)

**Uwaga implementacyjna**: po zielonych kryteriach stop na potwierdzenie i commit użytkownika.

---

## Faza 2: Feature Tablicy PR (ekrany, bez wpięcia)

### Przegląd

Nowy feature `FeaturesNew/PRBoard/` wg konwencji folderów: kategorie → ruchy w podgrupach → pusty szczegół. Kompiluje się i ma previews; nic go jeszcze nie prezentuje.

### Wymagane zmiany:

#### 1. Reducer główny (kategorie)

**Pliki**: `WorkoutMirrorLive/FeaturesNew/PRBoard/Feature/PRBoardFeature.swift` (+ `+State.swift`, `+Action.swift`) (nowe)

**Cel**: stan ekranu kategorii (liczniki 0/N z `PRCatalog`), nawigacja do listy ruchów.

**Kontrakt**: `@Reducer` + `@ObservableState`; `@Presents var movementList: PRMovementListFeature.State?`; `Action: ViewAction` (`categoryTapped(PRCategory)`, `closeTapped`); `@Dependency(\.dismiss)` dla zamknięcia. Zero niekontrolowanych zależności (lessons.md).

#### 2. Lista ruchów i szczegół (child features)

**Pliki**: `WorkoutMirrorLive/FeaturesNew/PRBoard/Child/PRMovementList/…` i `…/Child/PRMovementDetail/…` (Feature + View, nowe)

**Cel**: lista ruchów wybranej kategorii pogrupowana podgrupami (wszystkie wiersze „muted" — brak wpisów; klikalne) → pusty szczegół (nazwa EN, kategoria, nota Rx dla benchmarku, `ContentUnavailableView` „Brak wpisów — dodasz je wkrótce").

**Kontrakt**: lista: `@Presents var detail: PRMovementDetailFeature.State?`; push przez `.navigationDestination(item:)` (wzorzec PersonSettings); szczegół bez akcji poza dismiss.

#### 3. Widoki

**Pliki**: `PRBoardView.swift`, `PRMovementListView.swift`, `PRMovementDetailView.swift` (nowe, obok swoich Feature/)

**Cel**: warstwa prezentacji nieodróżnialna od StatsTab.

**Kontrakt**: `PRBoardView` = własny `NavigationStack` + `ScrollView + VStack(spacing: 12)`; karty kategorii `GroupBox` + `.styledGroupBox()` (label: caption + Divider; licznik "0 z N", kolor `PRCategory.color`); wiersze ruchów wg wzorca `ExerciseAnalyticsView.swift:156-221` (Button `.plain` + chevron), wariant muted kolorem `.secondary`/wagą (NIE `.disabled`); View Facade (sekcje jako `private var` na dole pliku); `@ViewAction`, zero `@State`, buttony verbose w `private var`; wszystkie teksty UI przez `String(localized:)`.

### Kryteria sukcesu:

#### Weryfikacja automatyczna:

- Struktura folderów zgodna z konwencją: `ls WorkoutMirrorLive/FeaturesNew/PRBoard/{Feature,Child}` przechodzi
- `grep -r "@State" WorkoutMirrorLive/FeaturesNew/PRBoard/` zwraca 0 trafień

#### Weryfikacja ręczna:

- Build `WorkoutMirrorLive` przechodzi (użytkownik)
- Preview PRBoardView renderuje kategorie z licznikami 0/N (użytkownik)

**Uwaga implementacyjna**: stop na potwierdzenie i commit użytkownika.

---

## Faza 3: Wpięcie w zakładkę Statystyki

### Przegląd

Jedyna modyfikacja istniejącego kodu: warunek per-segment w toolbarze + trzeci case Destination + fullScreenCover.

### Wymagane zmiany:

#### 1. Destination i akcja

**Pliki**: `WorkoutMirrorLive/FeaturesNew/StatsTab/Feature/StatsFeature+Destination.swift`, `StatsFeature+Action.swift`, `StatsFeature.swift`

**Cel**: nowy cel nawigacji Tablicy PR w istniejącym wzorcu.

**Kontrakt**: case `prBoard(PRBoardFeature)` w `Destination` (`+Destination.swift:13-22`); akcja `prBoardButtonTapped` (`+Action.swift`); reducer ustawia `state.destination = .prBoard(PRBoardFeature.State())` (wzorzec `StatsFeature.swift:148-150`).

#### 2. Toolbar per-segment i prezentacja

**Plik**: `WorkoutMirrorLive/FeaturesNew/StatsTab/StatsView.swift`

**Cel**: FR-010 — w segmencie Ćwiczenia wyłącznie przycisk Tablicy PR; FR-011 — pozostałe segmenty bez zmian.

**Kontrakt**: w `toolbarButton` (`:72-91`) if/else po `store.context == .exercises`: gałąź exercises = jeden `ToolbarItem(.topBarTrailing)` z przyciskiem Tablicy (ikona spójna z domeną, np. `trophy`) + `.matchedTransitionSource(id: "prBoard", in: zoomTransition)` NA ToolbarItem; gałąź else = dotychczasowe trzy itemy bez zmian. Prezentacja: `.fullScreenCover(item: $store.scope(state: \.destination?.prBoard, action: \.destination.prBoard)) { PRBoardView(store:).navigationTransition(.zoom(sourceID: "prBoard", in: zoomTransition)) }` (wzorzec `:60-64`). Przycisk w `private var` (konwencja).

### Kryteria sukcesu:

#### Weryfikacja automatyczna:

- `grep -rn "prBoard" WorkoutMirrorLive/FeaturesNew/StatsTab/` znajduje case, akcję i cover
- `swift test --package-path SharedModels` nadal zielone

#### Weryfikacja ręczna:

- Build `WorkoutMirrorLive` przechodzi (użytkownik)
- Pełny przepływ: Ćwiczenia → przycisk → kategorie → ruchy → pusty szczegół → powrót (użytkownik)
- Przełączanie segmentów bez migotania toolbara; Dziś/Analityka z pełnym toolbarem bez zmian (użytkownik)

**Uwaga implementacyjna**: ostatnia faza — po potwierdzeniu commit użytkownika + epilog.

---

## Strategia testowania

Bez nowych testów w S-01 (reguła repo). Weryfikacja: buildy, testy pakietów (regresja), previews i ręczny przepływ. Testy czystej funkcji PR — S-02 (jawne kryterium sukcesu PRD).

## Uwagi dotyczące migracji

Brak — katalog statyczny, zero zmian schematu.

## Referencje

- Badania: `context/changes/pr-board-entry-and-catalog/research.md`
- Roadmapa S-01 + PRD FR-001/002/009/010/011
- Wzorce: `StatsView.swift:60-91`, `PersonSettingsView.swift:39-53`, `WorkoutVocabulary.swift:73-249`, `ExerciseAnalyticsView.swift:156-221`

## Postęp

> Konwencja: `- [ ]` oczekujące, `- [x]` wykonane. Dodaj ` — <commit sha>` po zakończeniu kroku. Nie zmieniaj tytułów kroków.

### Faza 1: Katalog ruchów w SharedModels

#### Automatyczne

- [x] 1.1 `swift build --package-path SharedModels` przechodzi
- [x] 1.2 `swift test --package-path SharedModels` — istniejące testy zielone (bez nowych)

#### Ręczne

- [ ] 1.3 Polskie tłumaczenia kluczy kategorii/podgrup dodane w Xcode (użytkownik)

### Faza 2: Feature Tablicy PR (ekrany, bez wpięcia)

#### Automatyczne

- [ ] 2.1 Struktura folderów zgodna z konwencją: `ls WorkoutMirrorLive/FeaturesNew/PRBoard/{Feature,Child}` przechodzi
- [ ] 2.2 `grep -r "@State" WorkoutMirrorLive/FeaturesNew/PRBoard/` zwraca 0 trafień

#### Ręczne

- [ ] 2.3 Build `WorkoutMirrorLive` przechodzi (użytkownik)
- [ ] 2.4 Preview PRBoardView renderuje kategorie z licznikami 0/N (użytkownik)

### Faza 3: Wpięcie w zakładkę Statystyki

#### Automatyczne

- [ ] 3.1 `grep -rn "prBoard" WorkoutMirrorLive/FeaturesNew/StatsTab/` znajduje case, akcję i cover
- [ ] 3.2 `swift test --package-path SharedModels` nadal zielone

#### Ręczne

- [ ] 3.3 Build `WorkoutMirrorLive` przechodzi (użytkownik)
- [ ] 3.4 Pełny przepływ: Ćwiczenia → przycisk → kategorie → ruchy → pusty szczegół → powrót (użytkownik)
- [ ] 3.5 Przełączanie segmentów bez migotania toolbara; Dziś/Analityka z pełnym toolbarem bez zmian (użytkownik)
