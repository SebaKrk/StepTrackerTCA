# Poprawność PR wszystkich typów — Krótki plan

> Pełny plan: `context/changes/testing-pr-correctness-all-types/plan.md`
> Badania: `context/changes/testing-pr-correctness-all-types/research.md`

## Co i dlaczego

Faza 2 test-planu (ryzyko #1: użytkownik dobiera ciężar wg błędnie wyznaczonego PR). Siatka testów czystej funkcji PRResolver staje ZANIM S-03/S-04 dotkną logiki kierunków, remisów i rozdziału Rx/scaled — plus jedna zmiana zachowania (mieszane typy) zrobiona w pełnym TDD, jako materiał lekcji 3.2.

## Punkt wyjścia

14 testów resolvera dobrej jakości, ale 8 luk: remisy testowane tylko dla weight, isRx nil nietestowane, mieszane typy = cichy remis (błędny wpis nowszą datą ZOSTAJE PR-em). Doc-comment suity fałszywie przypisuje tie-break createdAt do PRD. 4 białe plamy wyroczni PRD rozstrzygnięte decyzjami przy tym planie.

## Pożądany stan końcowy

Każda reguła wyroczni (PRD + decyzje D1–D4) ma test w `swift test` (CI); wpis o typie niezgodnym z ruchem nigdy nie wygrywa i zostawia ślad `reportIssue`; źródła asercji są uczciwie cytowane.

## Kluczowe podjęte decyzje

| Decyzja | Wybór | Dlaczego | Źródło |
| --- | --- | --- | --- |
| D1: remis same-day | createdAt (później zapisany wygrywa) — reguła produktu | Deterministyczne, zgodne z „ostatnim podejściem"; zero zmian kodu | Plan (decyzja usera) |
| D2: benchmark scaled-only | scaled JEST PR-em (best = bestRx ?? bestScaled) | Użytkownik zawsze widzi swój najlepszy wynik | Plan (decyzja usera) |
| D3: isRx == nil na benchmarku | koszyk scaled | Ostrożna interpretacja — nigdy nie zawyża Rx | Plan (decyzja usera) |
| D4: mieszane typy | zgodny typ ZAWSZE wygrywa + reportIssue | Domyka wprost scenariusz ryzyka #1 po S-03 | Plan (decyzja usera) |
| Tryby wykonania | Faza 1/3 implement, Faza 2 TDD | TDD tylko tam, gdzie czerwony test nazywa się jednym zdaniem (lekcja 3.2) | Badania + Plan |

## Zakres

**W zakresie:** testy luk #1–#5 (charakteryzacja D1–D3), TDD luki #8 (D4 + IssueReporting w SharedModels), poprawka atrybucji doc-commentu, deliberate-break check, §6.6 cookbooka.

**Poza zakresem:** „oznaczenie pobicia" (brak API — iteracja 2), test anty-cache delete, UI/editor (S-03/S-04), PRScoreFormatter, liczniki per kategoria (warstwa aplikacji).

## Architektura / Podejście

Wszystko w czystej funkcji pakietu SharedModels — najtańsza warstwa, już w CI. Wyrocznia = PRD + D1–D4, nigdy implementacja. Charakteryzacja dla zachowań zatwierdzonych; czerwony-najpierw wyłącznie dla zmiany zachowania.

## Fazy w skrócie

| Faza | Co dostarcza | Kluczowe ryzyko |
| --- | --- | --- |
| 1. Brzegi wyroczni (implement) | ~7 testów dokumentujących + uczciwa atrybucja | — |
| 2. Mieszane typy (TDD) | red→green→refactor: zgodny typ wygrywa + reportIssue | withKnownIssue w tym samym commicie; IssueReporting przez stary URL |
| 3. Cookbook (implement) | §6.6 wzorzec charakteryzacja vs TDD | — |

**Wymagania wstępne:** brak (pakiet samodzielny)
**Szacowany wysiłek:** ~1 sesja, 3 fazy = 3 commity (`lesson3.2 (pK)`)

## Otwarte ryzyka i założenia

- Zmiana D4 dotyka porównania w resolverze — publiczne sygnatury bez zmian, konsumenci nietknięci (sanity build usera w fazie 3)

## Kryteria sukcesu (podsumowanie)

- Rename rawValue / zmiana filtru koszyków / regres porównań natychmiast failuje `swift test` w CI
- Błędny typ wpisu nie może zostać PR-em (scenariusz ryzyka #1 zamknięty przed S-03)
- Deliberate-break dowodzi, że asercje łapią regresję, nie tylko wykonują linie
