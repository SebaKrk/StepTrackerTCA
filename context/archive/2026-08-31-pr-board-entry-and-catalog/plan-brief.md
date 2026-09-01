# Tablica PR — wejście i katalog ruchów (S-01) — krótki plan

> Pełny plan: `context/changes/pr-board-entry-and-catalog/plan.md`
> Badania: `context/changes/pr-board-entry-and-catalog/research.md`

## Co i dlaczego

Pierwszy widoczny plaster Tablicy PR: użytkownik otwiera ją przyciskiem w segmencie Ćwiczenia i przegląda katalog 29 ruchów w 5 kategoriach (Olimpijskie, Siła, Gimnastyka, Kondycja, Benchmarki) z podgrupami i notami standardu Rx. To fundament nawigacyjno-katalogowy, na którym S-02 postawi wpisy i wyznaczanie PR.

## Punkt wyjścia

Zakładka Statystyki ma 3 segmenty i jeden wspólny toolbar (crown/AI/profil) bez żadnych warunków per-segment; katalogu ruchów PR nie ma; `MovementCategory` nie pokrywa domeny (brak Benchmarków). Research zmapował wzorce do skopiowania: warunkowy ToolbarItem, przycisk→Destination→fullScreenCover, katalog-jako-dane (WorkoutVocabulary), styl kart StatsTab.

## Pożądany stan końcowy

Z segmentu Ćwiczenia działa pełna ścieżka: przycisk (zamiast crown/AI/profilu — tylko tu) → kategorie z licznikami 0/N → ruchy w podgrupach (wyszarzone „muted", klikalne) → pusty szczegół z notą Rx benchmarku. Dziś/Analityka bez zmian, przełączanie bez migotania.

## Kluczowe podjęte decyzje

| Decyzja | Wybór | Dlaczego | Źródło |
| --- | --- | --- | --- |
| Prezentacja ekranu | fullScreenCover + zoom transition | 3-poziomowa hierarchia potrzebuje pełnego ekranu; wzorzec personSettings 1:1 | Plan (user) |
| Kategorie katalogu | Własny enum `PRCategory` (5 case'ów) | `MovementCategory` nie ma Benchmarków; nie ruszamy istniejącego typu | Badania |
| Wzorzec danych | `PRCatalog` à la WorkoutVocabulary | Single source of truth zamiast 600 linii równoległych switchy ExerciseType | Badania |
| Język katalogu | Nazwy ruchów EN, kategorie/podgrupy PL/EN | Konwencja fitness + spójność z ExerciseType.displayName | Plan (user) |
| Puste ruchy | Klikalne → pusty szczegół | Nawigacja end-to-end już w S-01; S-02 dokłada formularz w gotowe miejsce | Plan (user) |
| Lista rdzenia | 29 ruchów zaproponowanych w planie | User zatwierdza/przycina przy przeglądzie planu | Plan (user) |
| Wpięcie w toolbar | if/else wewnątrz istniejącego `toolbarButton` | Jeden toolbar = brak migotania; precedens warunkowego ToolbarItem istnieje | Badania |
| Testy | Zero nowych w S-01 | Reguła repo (bez proaktywnych testów); testy czystej funkcji = S-02 | Plan |

## Zakres

**W zakresie:** typy + dane katalogu w SharedModels (z uśpionymi mostkami `exerciseType`/`wodAliases`), feature `PRBoard` (3 ekrany), warunek toolbara + Destination + fullScreenCover.

**Poza zakresem:** wpisy/persystencja/migracje, formularz, wykresy, konsumpcja mostków, zmiany w ExerciseType/MovementCategory/skanie AI, testy jednostkowe, tłumaczenie nazw ruchów.

## Architektura / Podejście

Katalog = czyste dane w SharedModels (`PRCategory`, `PRMovement`, `PRCatalog.movements`). UI = nowy feature `FeaturesNew/PRBoard/` (TCA 1.26: `@Presents` + `.navigationDestination` we własnym NavigationStacku, zero `@State`), stylowany jak StatsTab (`GroupBox` + `.styledGroupBox()`). Wpięcie = trzeci case `StatsFeature.Destination` + warunek w istniejącym builderze toolbara.

## Fazy w skrócie

| Faza | Co dostarcza | Kluczowe ryzyko |
| --- | --- | --- |
| 1. Katalog w SharedModels | Typy + 29 ruchów, mostki uśpione | trafność listy rdzenia (user tnie przy review) |
| 2. Feature PRBoard | 3 ekrany z previews, bez wpięcia | wierność stylowi StatsTab (guardrail) |
| 3. Wpięcie w Statystyki | Przycisk w segmencie Ćwiczenia + cover | migotanie toolbara przy zmianie segmentu (FR-011, test ręczny) |

**Wymagania wstępne:** brak (S-01 ma w roadmapie Prerequisites: —; F-01 niepotrzebne dla S-01).
**Szacowany nakład:** ~1-2 sesje, 3 commity + epilog (commituje użytkownik).

## Otwarte ryzyka i założenia

- Zmiana liczby ToolbarItems przy przełączeniu segmentu może animować się nieładnie — jedyna weryfikacja to test ręczny (3.5); w razie problemu: stały ToolbarItem z podmienianą zawartością jako fallback.
- Lista 29 ruchów to propozycja — przycięcie/zamiana ruchów przy review planu nie zmienia architektury.

## Kryteria sukcesu (podsumowanie)

- Użytkownik przechodzi: Ćwiczenia → Tablica → kategoria → ruch → szczegół i wraca; reszta aplikacji bez zmian.
- Toolbar w Ćwiczeniach pokazuje wyłącznie przycisk Tablicy; Dziś/Analityka nietknięte, bez migotania.
- Testy pakietów zielone (CI), zero nowych zależności i zero zmian w bazie.
