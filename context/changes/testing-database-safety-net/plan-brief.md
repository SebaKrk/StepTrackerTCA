# Siatka bezpieczeństwa bazy — Krótki plan

> Pełny plan: `context/changes/testing-database-safety-net/plan.md`
> Badania: `context/changes/testing-database-safety-net/research.md`

## Co i dlaczego

Faza 1 wdrożenia test-planu: testy integracyjne in-memory dowodzące, że migracje i mapowania rekordów nie gubią danych użytkownika (ryzyka #2 i #3 — realny incydent utraty danych 2026-08-03 i „zapis udający sukces"). Dodatkowo, decyzją usera, od razu naprawiamy dwie znalezione produkcyjne ciche straty.

## Punkt wyjścia

Jedyny test bazy sprawdza migracje na PUSTEJ bazie — jest ślepy na scenariusz incydentu (erase odpala się tylko na bazie z danymi). Żaden z 11 rekordów nie ma testu round-trip. Reducer editora PR połyka błąd zapisu i zamyka sheet jak przy sukcesie; `toDomain()` znika wiersze bez śladu.

## Pożądany stan końcowy

`swift test --package-path AppDatabase` chroni: przetrwanie danych przy migracji, predykat DEBUG erase, kontrakt round-trip wszystkich 11 rekordów i udokumentowane defensywne przejścia. Błąd zapisu pokazuje alert (sheet zostaje), nil-collapse zostawia `reportIssue`. §6.2 test-planu opisuje, jak dodać kolejny test bazy.

## Kluczowe podjęte decyzje

| Decyzja | Wybór | Dlaczego | Źródło |
| --- | --- | --- | --- |
| Zakres produkcyjny | Naprawiamy oba fixy od razu (alert + reportIssue) | „Zapis udaje sukces" to realna luka UX; telemetria kończy niewidzialność defektów | Plan (decyzja usera) |
| Zakres rekordów | Wszystkie 11 z `Records/` | Pełna siatka warstwy, w tym najgorszy precedens (setsData `try?`) | Plan (decyzja usera) |
| Typy wyniku PREntry | Wszystkie 4 (weight/time/reps/amrap) | Testujemy kontrakt rekordu, nie editora — siatka staje PRZED S-03 | Badania + Plan |
| Defensive nil | Dokumentujemy testami (bez zmiany zachowania) | Rename rawValue = główny trigger straty; test failuje natychmiast | Badania + Plan |
| Fixture v11 | `migrate(upTo:)` + surowy SQL | Bez binarnych fixture'ów; struktury @Table mapują najnowszy schemat | Badania |

## Zakres

**W zakresie:** testy migratora z danymi, round-trip 11 rekordów, kontrakt throws TrainingSessionRecord, alert błędu zapisu w editorze + test TestStore, reportIssue w stratnych przejściach, §6.2/§6.6 test-planu.

**Poza zakresem:** nowe migracje/zmiany schematu, zmiana filozofii defensive-nil na throws, fix połknięcia przy delete (odnotowany kandydat), testy pozostałych przepływów TCA, zmiany CI.

## Architektura / Podejście

Warstwa pakietowa (AppDatabase, in-memory `DatabaseQueue` + publiczny `makeMigrator()`) niesie 3 z 4 faz — najtańszy `swift test`, już w CI. Warstwa app targetu (TestStore, Cmd+U) tylko tam, gdzie żyje reducer. Oczekiwane wartości zawsze jako literały fixture'ów (anty-wyrocznia).

## Fazy w skrócie

| Faza | Co dostarcza | Kluczowe ryzyko |
| --- | --- | --- |
| 1. Migrator z danymi | Test scenariusza incydentu + predykat erase | fixture SQL musi odzwierciedlać schemat v11 |
| 2. Round-trip PREntryRecord | Kontrakt 4 typów + defensive-nil udokumentowane | — |
| 3. Round-trip 10 rekordów | Pełna siatka Records/ (setsData!) | bogate fixture'y (wszystkie opcjonale wypełnione) |
| 4. Fixy + test błędu + cookbook | Alert zapisu, reportIssue, §6.2 | withKnownIssue w tym samym commicie co telemetria |

**Wymagania wstępne:** brak (wszystkie API publiczne; zero zmian produkcyjnych do fazy 3 włącznie)
**Szacowany wysiłek:** ~1-2 sesje, 4 fazy = 4 commity (`lesson3.1 (pK)`)

## Otwarte ryzyka i założenia

- `reportIssue` w pakiecie może wymagać jawnej zależności IssueReporting w Package.swift (dziś tranzytywna)
- Mapowania części z 10 rekordów mogą nie mieć symetrycznych API `init(from:)`/`toDomain()` — wtedy round-trip na poziomie dostępnego API danego rekordu

## Kryteria sukcesu (podsumowanie)

- Edycja historycznej migracji lub rename rawValue natychmiast failuje `swift test` (lokalnie i w CI)
- Nieudany zapis wpisu jest widoczny dla użytkownika; znikający wiersz zostawia ślad dla developera
- Nowy test bazy da się dodać wg przepisu z §6.2 bez czytania tego planu
