---
date: 2026-09-02T18:30:53+02:00
researcher: Claude Code (Fable 5)
git_commit: 5f966e1d5833287af6cee9a4cc75d4dc1507429b
branch: dev/10xDev/lesson3.2
repository: StepTrackerTCA
topic: "Ugruntowanie Fazy 2 test-planu: Risk #1 (błędny PR) — wyrocznia z PRD, mapa luk testów, powierzchnia S-03/S-04"
tags: [research, codebase, pr-resolver, shared-models, pr-board, tdd, oracle]
status: complete
last_updated: 2026-09-02
last_updated_by: Claude Code (Fable 5)
---

# Research: Poprawność PR wszystkich typów — wyrocznia i luki przed S-03/S-04

**Date**: 2026-09-02T18:30:53+02:00
**Researcher**: Claude Code (Fable 5)
**Git Commit**: 5f966e1d5833287af6cee9a4cc75d4dc1507429b
**Branch**: dev/10xDev/lesson3.2
**Repository**: StepTrackerTCA

## Research Question

Ground rollout Phase 2 of `context/foundation/test-plan.md` (Risk #1: użytkownik dobiera ciężar wg błędnie wyznaczonego PR). Zbudować WYROCZNIĘ ze źródeł (PRD FR-007/US-02/Business Logic — nie z implementacji resolvera), zmapować luki istniejącej suity, ugruntować powierzchnię, którą zmienią S-03 (kontrolki time/reps/AMRAP) i S-04 (UI Rx/scaled). Challenge: „istniejące testy resolvera pokrywają też przyszłe typy".

## Summary

- **Wyrocznia z PRD (8 reguł O1–O8)** jest kompletna dla rdzenia, ale ma **5 białych plam**, które implementacja dziś rozstrzyga bez źródła: tie-break `createdAt` przy remisie same-day, semantyka `best` przy scaled-only, `isRx == nil` na benchmarku → koszyk scaled, flaga isRx na ruchu bez wsparcia, mieszane typy score → cichy remis. **Doc-comment suity testowej fałszywie przypisuje tie-break createdAt do PRD** — to wybór implementacyjny wymagający jawnej decyzji (lekcja 3.2: „gdy źródła nie rozstrzygają — zatrzymaj się i zapytaj").
- **Challenge potwierdzony częściowo**: istniejące 14 testów jest dobrej jakości (fixture'y dyskryminujące, zero luster implementacji, zero redundancji), ale zostawia **8 luk** — najgroźniejsze: #1 `isRx == nil` (obszar S-04), #3/#4 remisy dla amrap/time/reps (tie testowany tylko na weight), #8 mieszane typy → błędny wpis nowszą datą wygrywa remisem (wprost scenariusz ryzyka #1 po S-03).
- **Powierzchnia S-03/S-04 zwarta**: jedyny punkt konstrukcji `PRScoreValue` w editorze to jedna linia; `bestRx`/`bestScaled` istnieją w modelu, ale ŻADEN widok ich nie konsumuje (wszystko czyta `summary.best`); kontrolki F-01 pasują: `TimePickerField` → time, `DNFFields` → amrap; dla reps brak gotowego steppera (najbliższy wzorzec: prywatny `stepperTile` w DNFFields). `PRScoreFormatter` obsługuje 4 typy, zero testów.
- **Idealne warunki dla `/10x-tdd`**: każda luka nazywa się jednym zdaniem czerwonego testu z wyrocznią z PRD/decyzji — czysta funkcja, pakiet w CI, red→green→refactor bez symulatora.

## Detailed Findings

### Wyrocznia ze źródeł (PRD — zbudowana bez zaglądania do resolvera)

| # | Reguła | Źródło |
|---|---|---|
| O1 | PR = czysta funkcja z historii; zero zdenormalizowanego „best"; usunięcie wpisu cofa PR | prd.md:101, :72 (US-01 AC), :97 (FR-006) |
| O2 | Kierunek per typ: czas — mniej = lepiej (waga/reps „więcej = lepiej" tylko implicite — PRD jawnie wymienia tylko czas) | prd.md:101, :49, :134 |
| O3 | AMRAP leksykograficznie: rundy, potem powtórzenia | prd.md:101, :134 |
| O4 | Rx i scaled = osobne rankingi; scaled NIGDY nie bije Rx | prd.md:101, :77-79 (US-02: Fran 6:30 scaled vs 8:10 Rx) |
| O5 | Remis rozstrzyga nowsza data | prd.md:101, :134 |
| O6 | Rx/scaled tylko gdzie ruch wspiera; benchmark → para (Rx, scaled) | prd.md:92 (FR-004), :136 |
| O7 | Wyjście obejmuje liczniki uzupełnienia kategorii, datę ostatniego PR, oznaczenie pobicia | prd.md:136, :66, :107 (FR-009) |
| O8 | PR liczony per ruch; wejście: wartość wg typu, flaga Rx/scaled, data | prd.md:101, :136 |

**Białe plamy wyroczni (PRD nie rozstrzyga — wymagają decyzji przy planie):**
1. Remis w tym samym dniu — tie-break po `createdAt`? (implementacja: tak, `PRResolver.swift:47-48`; doc-comment testów :12-14 błędnie przypisuje to PRD)
2. `best` benchmarku przy samych wpisach scaled — czy scaled-only jest „the PR"? (implementacja: `best = bestRx ?? bestScaled`, `:38`)
3. `isRx == nil` na ruchu wspierającym Rx/scaled → który koszyk? (implementacja: scaled — `:37` `$0.isRx != true`; doc `PREntry.swift:94` mówi „nil when the movement does not support Rx/scaled" — stan pół-legalny)
4. Flaga isRx na ruchu BEZ wsparcia → ignorowana? (implementacja: tak, guard `:33-34`)
5. Mieszane typy score w historii jednego ruchu → remis? (implementacja: `orderedSame`, `:86-87` — „never happen"; po S-03 błędny wpis nowszą datą WYGRAŁBY remisem)

### Mapa pokrycia — `SharedModels/Tests/SharedModelsTests/PRResolverTests.swift` (14 testów)

Pokryte solidnie: O2 (weight :48-54, time :56-62, reps :64-70), O3 (:72-78 — fixture 6+0 vs 5+10 dyskryminuje leksykografię od sumy; :80-86 extraReps), O5 dla weight (:90-96), O4 (:112-120 — wprost US-02), O6 bez wsparcia (:130-137), O8 filtr ruchu (:141-147), pusta historia (:149-155), helpers (:159-178).

**LUKI (8):**
1. `isRx == nil` na benchmarku → koszyk scaled — nietestowane (obszar S-04, regresja filtru `:37` przejdzie cicho)
2. isRx true/false na ruchu bez wsparcia → ignorowane — nietestowane
3. Remis AMRAP (równe rundy I extraReps → data/createdAt) — tie tylko na weight
4. Remis time i reps — jw.
5. Rx-only benchmark: `bestScaled == nil` + `best == bestRx` — nietestowane
6. „Usunięcie wpisu cofa PR" (O1) — konstrukcyjnie gwarantowane; test-strażnik przed przyszłym cache brak
7. „Oznaczenie pobicia" (prd.md:136) — **zero API i zero testów** (`isBetter` publiczny, ale brak „czy wpis pobił poprzedni PR")
8. Mieszane typy score → cichy remis (`:86-87`) — nietestowane, bez źródła; najgroźniejsza kombinacja z #1 po S-03

### Audyt jakości istniejących testów

Suita dobra: zero luster implementacji (oczekiwane wartości = ręcznie dobrane fixture'y, lepszy wynik celowo STARSZĄ datą), zero redundancji. Trzy zastrzeżenia: (a) doc-comment :12-14 rozszerza wyrocznię o createdAt podpisując PRD — fałszywa atrybucja; (b) `benchmarkScaledOnlyFallback` :122-128 przybija implementację (`best == scaled`), nie wyrocznię; (c) `completedMovementIds`/`latestEntryDate` :159-178 prawie tautologiczne wobec jednolinijkowych implementacji — prawdziwa wyrocznia (FR-009: liczniki per kategoria) żyje warstwę wyżej, nieprzetestowana.

### API resolvera i nadwyżka implementacyjna

`PRResolver.swift`: `PRSummary{best,bestRx,bestScaled}` :12-22, `summary(for:entries:)` :31, `isBetter(_:than:)` :42, `completedMovementIds` :53, `latestEntryDate` :58. Nadwyżka bez źródła w PRD: tie-break createdAt (:47-48), `isRx != true` → scaled (:37), `best = bestRx ?? bestScaled` (:38), mieszane typy → remis (:86-87). `completedMovementIds`/`latestEntryDate` mają źródło pośrednie w FR-009 (wymaganie widoku).

### Katalog per scoreType (zasięg S-03/S-04)

`PRCatalog.swift:14-54`, `PRMovement.swift:59,:74`: 29 ruchów — **weight 13** (olimpijskie 5 + siła 8), **time 10** (kondycja 5 + benchmarki Fran/Grace/Helen/Diane/Murph), **reps 5** (gimnastyka), **amrap 1** (Cindy). `supportsRxScaled` — wyłącznie 6 benchmarków. S-03 dotyka 16 ruchów; S-04 — 6; Cindy (jedyny AMRAP) leży w obu i jest najsłabiej pokrytym brzegiem (luki #1+#3).

### Powierzchnia S-03 w aplikacji

- Jedyny punkt konstrukcji `PRScoreValue`: `PREntryEditorFeature.swift:36` (`score: .weight(...)`; guard parsedWeight :30; przepisanie 1:1 do enriched :52)
- Walidacja tekstowa tylko dla weight: `+State.swift:32,:57-62,:64` (`isSaveDisabled`); gate przycisku `PREntryEditorView.swift:183`
- Guard S-02: `PRMovementDetailFeature+State.swift:58` `supportsEntryForm { movement.scoreType == .weight }` (+ komentarz :56-57); użycia w View :265 (toolbar), :251-253 (empty state „coming soon"), :256 (przycisk)
- Już scoreType-aware w detalu (betonować przed S-03): `isTimeScored` :78, `scalar(for:)` :99-106 (AMRAP = rounds + extraReps/100), `chartYDomain` `PRMovementDetailView.swift:177-182`, `yAxisLabel` mm:ss :184-190, `bodyWeightMultiple` tylko weight `+State.swift:62-70`
- `PRScoreFormatter.swift:15-33` — 4 typy („150 kg", „%d:%02d", „21 reps", „6+7") — **zero testów**; duplikacja logiki czasu z `yAxisLabel` (dwie ścieżki muszą zostać zgodne)

### Powierzchnia S-04 w aplikacji

Żaden widok nie rozróżnia Rx/scaled — wszystko czyta `summary.best`: `PRMovementListFeature+State.swift:61`, `PRMovementDetailView.swift:38` (currentPRCard :100-128), `bodyWeightMultiple`. Historia (:213-234) bez badge per wpis. Jedyne Rx-aware: editor (picker `PREntryEditorView.swift:97-103`, zapis `PREntryEditorFeature.swift:37`).

### Kontrolki F-01 do reużycia (FR-005: bez parsowania tekstu)

- `UI/ResultEntry/TimePickerField.swift:12-21` — mm:ss wheels (`minutes/seconds/maxMinutes` + closures) → pasuje 1:1 do `.time`
- `UI/ResultEntry/DNFFields.swift:13-22` — rounds + extraReps stepper tiles → pasuje do `.amrap` (komentarz w pliku wprost)
- `.reps`: brak gotowego steppera; najbliższy wzorzec — prywatny `stepperTile` w DNFFields :60-90
- Uwaga: obie kontrolki themowane `@Environment(\.summaryPalette)` (dark Summary) — w Form editora decyzja o theming przy S-03
- `SetTable.swift` — nie pasuje (multi-set, pola tekstowe)

### Testy istniejące poza SharedModels

`WorkoutMirrorLiveTests/PREntryEditorFeatureTests.swift` — 3 testy TestStore; `saveFlowPersistsEntryAndDismisses` :22 asertuje `.weight(kilograms: 150)` (:54) — wymaga rozszerzenia przy S-03. Zero testów PRMovementDetail (guard, chart scalars), PRScoreFormatter, PRMovementList.

## Code References

- `SharedModels/Sources/SharedModels/SharedModels/PRCatalog/PRResolver.swift:31-58,86-87` — API + nadwyżka implementacyjna
- `SharedModels/Tests/SharedModelsTests/PRResolverTests.swift:12-14,48-178` — suita 14 testów + fałszywa atrybucja doc-commentu
- `SharedModels/Sources/SharedModels/SharedModels/PRCatalog/PRCatalog.swift:14-54` — 29 ruchów per scoreType
- `SharedModels/Sources/SharedModels/SharedModels/PRCatalog/PREntry.swift:94` — doc isRx (nil = ruch bez wsparcia)
- `WorkoutMirrorLive/FeaturesNew/PRBoard/Child/PREntryEditor/Feature/PREntryEditorFeature.swift:30,36,52` — jedyny punkt konstrukcji score
- `WorkoutMirrorLive/FeaturesNew/PRBoard/Child/PRMovementDetail/Feature/PRMovementDetailFeature+State.swift:58,78,99-106` — guard + logika scoreType
- `WorkoutMirrorLive/FeaturesNew/PRBoard/Utilities/PRScoreFormatter.swift:15-33` — formatter 4 typów bez testów
- `WorkoutMirrorLive/UI/ResultEntry/TimePickerField.swift:12-21`, `.../DNFFields.swift:13-22` — kontrolki F-01

## Architecture Insights

- Resolver jest czystą funkcją w pakiecie SPM już w CI — czerwone testy TDD nie wymagają żadnej infrastruktury; to najtańsza możliwa warstwa dla ryzyka #1.
- Wzorzec „wyrocznia ≠ implementacja" złamany w jednym miejscu: doc-comment suity podpisuje wybór implementacyjny (createdAt) jako regułę PRD — do naprawy przy tej fazie (jawna decyzja + poprawka atrybucji).
- `best = bestRx ?? bestScaled` to interpretacja, na której NIC w UI jeszcze nie wisi poza pojedynczą etykietą — decyzja o semantyce jest tania TERAZ, droga po S-04.

## Historical Context (from prior changes)

- `context/archive/2026-08-31-record-entry-current-pr/` — S-02: powstanie PRResolver + 14 testów; tie-break createdAt dodany tam jako wybór projektowy (PREntry.createdAt doc: „breaks ties between same-day duplicates").
- `context/archive/2026-09-01-progress-views-polish/` — S-06: `supportsEntryForm` guard („do S-03"), oś odwrócona dla time.
- `context/foundation/test-plan.md` §2 Risk #1, §3 Faza 2 — intencja tej fazy.

## Related Research

- `context/archive/2026-09-02-testing-database-safety-net/research.md` — Faza 1 (warstwa bazy; granica pakietu).

## Open Questions

Białe plamy wyroczni wymagające decyzji użytkownika przy `/10x-plan` (lekcja 3.2: nie zgadywać — pytać):
1. Tie-break same-day po `createdAt` — potwierdzić jako regułę produktu (i naprawić atrybucję w doc-commencie)?
2. `best` benchmarku przy scaled-only — scaled jest „the PR" czy „brak PR Rx"?
3. `isRx == nil` na benchmarku — koszyk scaled, odrzucenie, czy wymuszenie wyboru w formularzu (S-04)?
4. Mieszane typy score — zostawić cichy remis czy zbetonować „nigdy nie wygrywa z poprawnym typem" / reportIssue?
