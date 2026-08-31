---
date: 2026-08-31T12:56:31+0200
researcher: Claude (Fable 5) + Sebastian Ściuba
git_commit: 1bb6e03c80d71738d264afed1d6fb0d062f42325
branch: dev/10xDev/lesson2.4
repository: StepTrackerTCA (MyFitnessJournal)
topic: "S-01 pr-board-entry-and-catalog: wejście do Tablicy PR z segmentu Ćwiczenia + statyczny katalog ruchów"
tags: [research, codebase, stats-tab, toolbar, exercise-catalog, tca-patterns, pr-board]
status: complete
last_updated: 2026-08-31
last_updated_by: Claude (Fable 5)
---

# Research: S-01 — wejście do Tablicy PR i przeglądanie katalogu ruchów

**Date**: 2026-08-31T12:56:31+0200
**Git Commit**: 1bb6e03 (`lesson2.3`)
**Branch**: dev/10xDev/lesson2.4

## Research Question

Grunt pod plan S-01 (FR-001, FR-002, FR-009 stany puste, FR-010, FR-011): (1) mechanika toolbara i segmentów zakładki Statystyki pod warunek widoczności per-segment; (2) wzorzec statycznego katalogu w kodzie pod katalog ruchów PR z uśpionymi mostkami; (3) wzorce „nowego feature'a" (nawigacja, stylowanie, stany puste, lokalizacja), by ekran był nieodróżnialny od reszty aplikacji.

## Summary

- **Toolbar StatsTab nie ma dziś żadnego warunku per-segment** — jedyny warunek to dostępność AI (DEBUG/tier). Wybrany segment żyje w `StatsFeature.State.context` (`StatsFeatureContext: today/analytics/exercises`), a toolbar (`@ToolbarContentBuilder var toolbarButton`) jest przyklejony do `rootView` w gałęzi `.success`. Warunkowanie `ToolbarItem` od stanu ma gotowy precedens w `ExerciseDetailView.swift:68-76`.
- **Wzorzec nawigacji z toolbara jest odwzorowany 1:1**: przycisk → `send(.xxxTapped)` → reducer ustawia `state.destination = .case(...)` → `.fullScreenCover/.sheet(item: $store.scope(...))`. `StatsFeature` ma już `enum Destination` (2 case'y: `personSettings` fullScreenCover+zoom, `readinessAnalysis` sheet+detents) — Tablica PR to trzeci case.
- **Istniejący `MovementCategory` NIE pokrywa 5 kategorii Tablicy** (brak „Benchmarków", nadmiarowe `mobility`/`mixed`) — katalog PR potrzebuje własnego enuma kategorii. Najlepszy wzorzec „katalog jako dane w kodzie" to `WorkoutVocabulary` (namespace-enum + słownik `categoryMap` jako single source of truth + publiczne API); wzorzec „enum z równoległymi switchami" to `ExerciseType`/`ExerciseWorkoutType`.
- **`wodAliases` nie istnieje nigdzie w kodzie** — mostek będzie faktycznie uśpiony; `wodName` to dziś czysta etykieta display bez żadnego dopasowywania. Mostek `exerciseType` mapuje się na istniejący `ExerciseType` (Codable, rawValue = nazwa case'a).
- **Guardrail wizualny ma jasną receptę**: `ScrollView + VStack(spacing: 12)` + `GroupBox` z labelem (caption + Divider) + `.styledGroupBox()`; NIE `List` (ta jest tylko w ekranach Settings). Puste stany: `ContentUnavailableView` (pełny ekran/karta) albo inline caption `.secondary`. Wyszarzanie: `.disabledWithOpacity()` z `UI/` lub wzorzec „muted" z `ExerciseList` (kolor/waga, nie opacity).

## Detailed Findings

### 1. Toolbar i segmenty zakładki Statystyki (FR-010, FR-011)

- `StatsView.swift:24-41` — `body` = `NavigationStack { switch store.viewState }`; toolbar żyje TYLKO w gałęzi `.success`: `.toolbar { toolbarButton }` na `rootView` (`:52-54`).
- `StatsView.swift:72-91` — `@ToolbarContentBuilder private var toolbarButton: some ToolbarContent`: crown = `ToolbarItem(.topBarLeading) { subscriptionTierMenu }` (`:74-76`); AI warunkowo (`#if DEBUG` / tier elite, `:77-86`); person = `ToolbarItem(.topBarTrailing) { personButton }` + `.matchedTransitionSource(id: "personSettings")` na ToolbarItem (`:87-90`).
- Segment: `Picker(.segmented)` w `.safeAreaBar(edge: .top)` (`StatsView.swift:142-160`); stan `var context: StatsFeatureContext = .today` (`StatsFeature+State.swift:39`); enum `today/analytics/exercises` (`StatsFeature+Enum.swift:16-42`, tytuły lokalizowane `bundle: .main`); akcja `selectedPickerChange` z lazy initem segmentów (`StatsFeature.swift:34-42`).
- Hierarchia per segment: `switch store.context` w `Group` wewnątrz `rootView` (`StatsView.swift:131-147`) — toolbar i navigationTitle są NAD switchem, więc nie przełączają się per segment (dobra wiadomość dla „bez migotania": zmienia się tylko zawartość `Group`).
- Segment Ćwiczenia = `ExerciseAnalyticsView` przez `store.scope(state: \.exerciseAnalytics)` (`StatsView.swift:183-188`); ten feature NIE deklaruje własnego toolbara ani NavigationStacka — czysta sytuacja pod warunek w `toolbarButton`.
- **Precedens toolbara zależnego od stanu**: `ExerciseDetailView.swift:68-76` — `@ToolbarContentBuilder` z `if store.exerciseType == .unknown, !store.unmatchedNameCounts.isEmpty { ToolbarItem(...) }`.
- Nawigacja z toolbara (wzorzec do skopiowania): `StatsFeature+Destination.swift:13-22` (`@Reducer enum Destination { personSettings, readinessAnalysis }`); reducer `StatsFeature.swift:123-125, 148-150`; modifiery `StatsView.swift:60-69` (`fullScreenCover` + zoom / `sheet` + detents); wiring `.ifLet(\.$destination)` (`StatsFeature.swift:181`).
- „Migotanie toolbara": zero istniejących technik/incydentów w repo (grep flicker/toolbarVisibility/toolbar(id:) — brak w StatsTab). Ryzyko leży w tym, że warunkowe `ToolbarItem` w `@ToolbarContentBuilder` zmienia LICZBĘ itemów przy przełączeniu segmentu — kryterium FR-011 trzeba zweryfikować ręcznie na urządzeniu/symulatorze.
- Uwaga techniczna: pomocnicze widoki segmentu Dziś używają legacy `IfLetStore` (`StatsView+Components.swift:15,29,43`) — złamanie zakazu TCA 1.26 z CLAUDE.md; NIE dotykamy w S-01, ale nie kopiować tego wzorca.

### 2. Statyczny katalog ruchów (FR-001, FR-002)

- `ExerciseType.swift` (586 linii): enum + równoległe switche `displayName` (`:154-267`, stringi NIEzlokalizowane), `aliases` (`:269-492`), `category` (`:494-531`), `requiresWeight` (`:532-544`), `catalogVersion = 6` (`:551`), matcher `matched(fromRawName:)` (`:558-585`). Sekcje case'ów jako komentarze z tagiem wersji.
- `MovementCategory.swift` (33 linie): 6 case'ów `strength/olympicLifting/gymnastics/cardio/mobility/mixed`, `displayName` ZLOKALIZOWANY (`String(localized:, bundle: .module)`), `color`. **Nie pokrywa** kategorii Tablicy: brak „Benchmarków", Kondycja rozmyta między `cardio` i `mixed`. Wniosek: katalog PR definiuje własny enum kategorii (5 stałych z PRD), bez dotykania `MovementCategory`.
- Najlepszy wzorzec „katalog danych": `WorkoutVocabulary.swift` — namespace-enum, `private static let categoryMap: [Category: [String]]` jako single source of truth (`:120`), publiczne API `allWords/words(for:)/allCategorized` (`:199-249`).
- Bliźniaczy wzorzec matchera: `ExerciseWorkoutType.swift` — `displayName/aliases/matching(_:)` (`:99`, aliasy <4 znaki tylko exact match).
- Struktura pakietu SharedModels: enum → `SharedEnum/<NazwaTypu>/`, model → `SharedModels/<NazwaModelu>/`; `defaultLocalization: en`, lokalizacja przez `Resources/Localizable.xcstrings` + `bundle: .module`; zależność tylko od Commons.
- Golden testy: `ExerciseTypeMatchingTests.swift` — `@Suite` + `static let fieldDataGolden: [(rawName, expected)]` + `@Test(arguments:)`; bloki komentarzy per wersja katalogu. Wzorzec do ewentualnych testów katalogu PR (swift-testing, nie XCTest).
- Mostki: `wodAliases` NIE istnieje w kodzie (0 trafień) — dopiero katalog PR go wprowadzi (uśpiony). `wodName` = etykieta display (`ExerciseLog.swift:57`), zapis z `result.name` bez normalizacji (`SummaryFeature.swift:260`), zero dopasowywania. Mostek typowany: `exerciseType: ExerciseType?` — bez zmian w ExerciseType v6 (constraint z PRD: żadnych nowych case'ów/aliasów).
- Precedens „5 kategorii + benchmarki osobno" istnieje TYLKO w legacy `StepTrackerTCA/Model/Enum/Movements/` (Movement/HeroMovement itd.) — target przeznaczony do usunięcia, NIE dotykać i NIE importować; co najwyżej inspiracja nazewnicza.
- `ScalingType` (`rx/scaled/rxPlus`) istnieje w SharedModels — nota „standard Rx" przy benchmarkach to nowe pole katalogu PR (String?), nie rozszerzenie ScalingType.

### 3. Wzorce nowego feature'a (FR-009 — ekrany, stany puste)

- Najnowszy wzorzec lista→szczegół: `ExerciseAnalytics` — folder `Feature/` (+State/+Action), View w root, `Child/ExerciseDetail/`; single-child `@Presents var detail` + `.sheet(item:)` z własnym `NavigationStack` (`ExerciseAnalyticsView.swift:34-38`); trzeci poziom pushem `.navigationDestination(item:)` (`ExerciseDetailView.swift:47-49`).
- Kanoniczny multi-case `enum Destination`: `PersonSettingsFeature+Destination.swift:13-29` + `.navigationDestination(item: $store.scope(state: \.destination?.case))` (`PersonSettingsView.swift:39-53`).
- Stylowanie (nieodróżnialność wizualna): `ScrollView { VStack(spacing: 12) }` + `GroupBox { } label: { Text(.caption).foregroundStyle(.secondary); Divider() }` + `.styledGroupBox()` (radius 24 continuous, stroke gray 0.5, fill secondarySystemBackground gradient) — wzorce: `AnalyticsView.swift:20-32`, `RingActivitiesSummaryView.swift:31-46`, lista wierszy w karcie: `ExerciseAnalyticsView.swift:156-221` (ForEach + Divider, wiersz = `Button` `.plain` + chevron). `List` tylko w Settings-owych ekranach.
- Wyszarzanie: `disabledWithOpacity(_:opacity:)` (`UI/View+Extension/View+DisabledOpacity.swift:11-15`); wariant „muted" kolorem: `UI/Summary/ExerciseList.swift:20,84-85`. Dla „ruchy puste wyszarzone, ale widoczne (i klikalne)" pasuje wariant kolor/waga — NIE `.disabled` (ruch pusty ma być wejściem do szczegółu/dodania wpisu w S-02; w S-01 wiersz może być nieklikalny — decyzja przy planie).
- Puste stany: `ContentUnavailableView` (wzorzec: `StatsView.swift:192-204` z Label+description+akcją) albo inline caption (`ExerciseAnalyticsView.swift:196-202`). `OverlayView`/`subscriptionOverlay` tylko dla gated/HealthKit — nie dotyczy S-01.
- Lokalizacja: `String(localized:)` + `Localizable.xcstrings` (700 wpisów); w enumach `bundle: .main` (`StatsFeature+Enum.swift:34-38`). Uwaga: katalog PR w SharedModels lokalizowałby przez `bundle: .module` (jak MovementCategory) — decyzja przy planie: displayName ruchów PL/EN czy tylko EN jak ExerciseType.
- Nagłówki sekcji: brak konwencji `.textCase(.uppercase)` na nagłówkach list — GroupBox label caption+Divider; `.textCase(.uppercase)` tylko na mikro-labelach w UI/ (MetricTile, ScoreLine, DNFFields itd.).

## Code References

- `WorkoutMirrorLive/FeaturesNew/StatsTab/StatsView.swift:52-54,72-91,131-160` — toolbar, segmenty, switch per segment
- `WorkoutMirrorLive/FeaturesNew/StatsTab/Feature/StatsFeature+Destination.swift:13-22` — Destination do rozszerzenia o Tablicę PR
- `WorkoutMirrorLive/FeaturesNew/StatsTab/Feature/StatsFeature+State.swift:39` — `context: StatsFeatureContext`
- `WorkoutMirrorLive/FeaturesNew/ExerciseAnalytics/Child/ExerciseDetail/ExerciseDetailView.swift:68-76` — precedens warunkowego ToolbarItem
- `SharedModels/Sources/SharedModels/SharedEnum/ExerciseType/ExerciseType.swift:551,558-585` — catalogVersion, matcher
- `SharedModels/Sources/SharedModels/SharedEnum/MovementCategory/MovementCategory.swift:4-33` — istniejące kategorie (nie pokrywają PR)
- `SharedModels/Sources/SharedModels/SharedModels/WorkoutVocabulary/WorkoutVocabulary.swift:73-249` — wzorzec katalogu-danych
- `SharedModels/Tests/SharedModelsTests/ExerciseTypeMatchingTests.swift:11-137` — format golden testów (swift-testing)
- `WorkoutMirrorLive/UI/ViewModifier/StyledGroupBoxModifier.swift:11-21` — wygląd kart
- `WorkoutMirrorLive/UI/View+Extension/View+DisabledOpacity.swift:11-15` — wyszarzanie
- `WorkoutMirrorLive/UI/Summary/ExerciseList.swift:20,84-85` — wzorzec „muted row"

## Architecture Insights

- Toolbar zakładki jest wspólny dla segmentów z konstrukcji (nad switchem) — FR-010 to warunek `if store.context == .exercises` wewnątrz `toolbarButton`, nie nowy toolbar per segment. Zmiana liczby ToolbarItems przy przełączaniu = jedyne realne ryzyko „migotania" (FR-011) — weryfikacja wyłącznie ręczna.
- Nowy ekran Tablicy najspójniej wchodzi jako trzeci case `StatsFeature.Destination` (prezentacja fullScreenCover lub sheet — decyzja przy planie), z własnym feature'em w `FeaturesNew/` wg konwencji folderów.
- Katalog ruchów PR: nowe typy w SharedModels (enum kategorii + struct wpisu + statyczne dane), wzorzec WorkoutVocabulary/ExerciseType; mostki `exerciseType: ExerciseType?` + `wodAliases: [String]` jako pola wpisu, w MVP nieczytane przez żaden mechanizm.
- Repo ma dwa smaki prezentacji child: single-child `@Presents var x: Feature.State?` (gdy jeden cel) i `enum Destination` (gdy wiele) — dla hierarchii kategorie→ruchy→szczegół naturalny jest push `.navigationDestination` wewnątrz własnego NavigationStacka ekranu Tablicy (wzorzec PersonSettings), NIE StackState.

## Historical Context (from prior changes)

- `context/changes/shared-result-input-components/` (F-01, impl_reviewed) — kontrolki wyników i motyw są już w `UI/ResultEntry/`; S-01 ich nie potrzebuje (to grunt pod S-02), ale motyw `SummaryPalette` NIE jest wzorcem dla Tablicy — Tablica ma wyglądać jak StatsTab (styledGroupBox), nie jak Summary.
- `context/foundation/lessons.md` — obowiązujące przy planie S-01: reducer bez niekontrolowanych zależności (`@Dependency(\.date)` itd.); wersjonowany katalog = bump + golden testy w tym samym commicie (dotyczy przyszłych rozszerzeń katalogu PR, nie MVP); migracje append-only (S-01 NIE dotyka bazy — katalog jest statyczny, wpisy dopiero w S-02).

## Related Research

- `context/foundation/roadmap.md` — S-01 (`pr-board-entry-and-catalog`), Prerequisites: —, Parallel with: F-01
- `context/foundation/prd.md` — FR-001, FR-002, FR-009, FR-010, FR-011 + Constraints (zero zmian w ExerciseType v6)

## Open Questions

1. Prezentacja Tablicy: `fullScreenCover` (jak personSettings, z zoom transition od przycisku) czy `sheet` z detentami? → decyzja przy planie (UX).
2. Lokalizacja displayName ruchów katalogu PR: PL/EN przez `bundle: .module` (jak MovementCategory) czy EN-only (jak ExerciseType)? → decyzja przy planie.
3. Czy wiersz „pustego" ruchu w S-01 jest klikalny (pusty szczegół) czy nieaktywny do czasu S-02? → decyzja przy planie (FR-009 mówi „wyszarzone, ale widoczne").
