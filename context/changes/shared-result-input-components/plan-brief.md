# Wydzielenie komponentów UI Summary — krótki plan

> Pełny plan: `context/changes/shared-result-input-components/plan.md`

## Co i dlaczego

Przenosimy komponenty UI z prywatnego folderu feature'a Summary do współdzielonej warstwy `WorkoutMirrorLive/UI/`. Powód: Tablica PR (S-02/S-03 roadmapy) potrzebuje tych samych kontrolek wpisywania wyników (mm:ss, rundy+powtórzenia, serie siłowe), a PRD (FR-005) nakazuje reużycie zamiast pisania od zera. To fundament F-01 milestone'u `pr-board-mvp`.

## Punkt wyjścia

15 komponentów żyje w `Summary/Components/`, wszystkie `internal` i feature-scoped; motyw `SummaryTheme` już dziś nielegalnie wycieka poza Summary (UI/HeartRate, ActivityPlanScore). Kontrolki są czyste (closure-driven, bez `@State`); jedynie `InlineResultEditor` jest spięty ze store'em. `Child/SetInput/` okazał się martwym kodem (zero użyć).

## Pożądany stan końcowy

`Summary/Components/` nie istnieje. `UI/ResultEntry/` trzyma 4 pliki współdzielone (TimePickerField, DNFFields, SetTable, SummaryTheme), `UI/Summary/` — 11 pozostałych. Aplikacja buduje się i wygląda w 100% identycznie; diff to wyłącznie przeniesienia plików (rename 100%).

## Kluczowe podjęte decyzje

| Decyzja | Wybór | Dlaczego | Źródło |
| --- | --- | --- | --- |
| Miejsce docelowe | `WorkoutMirrorLive/UI/` (nie Commons/SPM) | Konwencja repo: UI/ = shared widoki; Commons jest Foundation-only; ten sam target = zero zmian importów | Plan |
| Zakres przenosin | Wszystkie 15 plików, nie tylko 4 współdzielone | Decyzja użytkownika („cały UI w UI/") po omówieniu kompromisów | Plan (user) |
| InlineResultEditor | Przenosimy plik bez przepisywania | Store-driven klej feature'a; Tablica PR złoży własny formularz z kontrolek liściowych | Plan |
| Martwy SetInput (538 linii) | Zostaje, tylko odnotowany | Decyzja użytkownika; kandydat na osobny ticket porządkowy | Plan (user) |
| Podział na fazy | 2 fazy = 2 atomowe commity | Faza 1 odblokowuje S-02 (sedno F-01); faza 2 to porządki — rozdzielenie ułatwia review i ewentualny revert | Plan |

## Zakres

**W zakresie:** przeniesienie 15 plików (`git mv`), usunięcie pustego folderu `Components/`.

**Poza zakresem:** jakiekolwiek zmiany treści plików, kasowanie SetInput, przepisywanie InlineResultEditor, adaptacja twardych kolorów do palety `.native`, zmiany nazw typów.

## Architektura / Podejście

Czyste przenosiny w obrębie jednego targetu — projekt używa folder-sync (`fileSystemSynchronizedGroups`), więc Xcode podnosi pliki z nowych ścieżek bez edycji pbxproj, a brak granicy modułu oznacza zero zmian importów. Weryfikacja niezmienności: `git diff -M` musi pokazywać wyłącznie rename 100%.

## Fazy w skrócie

| Faza | Co dostarcza | Kluczowe ryzyko |
| --- | --- | --- |
| 1. Kontrolki → `UI/ResultEntry/` | 4 pliki odblokowujące S-02/S-03 | przypadkowa edycja treści zamiast czystego mv |
| 2. Reszta → `UI/Summary/` | „cały UI w UI/", pusty Components/ | plik spoza listy w folderze (weryfikacja ls przed mv) |

**Wymagania wstępne:** czysty working tree; branch `dev/10xDev/lesson2.2`.
**Szacowany nakład:** 1 krótka sesja, 2 commity (commituje użytkownik).

## Otwarte ryzyka i założenia

- Założenie: folder-sync obejmuje `UI/` i `FeaturesNew/` tym samym korzeniem targetu — potwierdzone precedensem `HRMinuteRangeChart` (ruch verbatim Summary → UI/HeartRate).
- Nazwa `SummaryTheme` w warstwie współdzielonej robi się myląca — świadomie odłożone (osobna mechaniczna zmiana).

## Kryteria sukcesu (podsumowanie)

- Build przechodzi, a Summary i wynik planu w ActivityDetails wyglądają w 100% identycznie.
- `git diff -M --summary` pokazuje wyłącznie przeniesienia (rename 100%) — zero zmian treści.
- Tablica PR (S-02) może importować kontrolki bez sięgania do folderu cudzego feature'a.
