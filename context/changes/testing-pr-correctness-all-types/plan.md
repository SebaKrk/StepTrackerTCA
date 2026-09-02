# Plan implementacji: Poprawność PR wszystkich typów (test-plan §3 Faza 2)

## Przegląd

Rozszerzenie suity `PRResolverTests` o brzegi wyroczni (luki #1–#5 z research) jako testy dokumentujące + jedna zmiana produkcyjna w resolverze (mieszane typy wyniku — zgodny typ wygrywa + telemetria) wykonana w pełnym cyklu TDD red→green→refactor. Realizuje ryzyko #1 test-planu PRZED implementacją S-03/S-04. Fazy oznaczone trybem wykonania: 1 i 3 — `/10x-implement`, 2 — `/10x-tdd` (wzorzec mieszania z lekcji 3.2).

## Analiza stanu obecnego

Z `context/changes/testing-pr-correctness-all-types/research.md` (2026-09-02, commit 5f966e1):

- Suita `PRResolverTests.swift` (14 testów) zdrowa: zero luster implementacji, dyskryminujące fixture'y; ale 8 luk — w planie zamykamy #1–#5 i #8; #6 (delete cofa PR — konstrukcyjnie gwarantowane) i #7 (oznaczenie pobicia — brak API, wymaganie widoku) poza zakresem.
- Doc-comment suity (`PRResolverTests.swift:12-14`) fałszywie przypisuje tie-break `createdAt` do PRD — wybór implementacyjny z S-02 udający wyrocznię.
- `PRResolver.swift`: `isRx != true` → koszyk scaled (`:37`), `best = bestRx ?? bestScaled` (`:38`), tie-break createdAt (`:47-48`), mieszane typy → `orderedSame` (`:86-87`) — błędny wpis nowszą datą WYGRYWA remisem.
- Katalog: 29 ruchów (13 weight / 10 time / 5 reps / 1 amrap); `supportsRxScaled` tylko 6 benchmarków; Cindy (jedyny AMRAP) w przecięciu S-03∩S-04.

## Pożądany stan końcowy

- Każda reguła wyroczni (PRD O1–O8 + 4 decyzje D1–D4 z tego planu) ma test w `swift test --package-path SharedModels`; rename rawValue, zmiana filtru koszyków lub regres porównań failuje suitę w CI.
- Wpis o typie niezgodnym z ruchem NIGDY nie zostaje PR-em i zostawia `reportIssue` (domyka scenariusz ryzyka #1 po S-03).
- Doc-comment suity cytuje prawdziwe źródła (PRD + decyzje planu).

### Kluczowe odkrycia:

- Luki #1–#5 to zachowania JUŻ poprawne — testy dokumentujące (zielone od razu, charakteryzacja); luka #8 to zachowanie DOCELOWE — jedyny prawdziwy czerwony test (TDD)
- IssueReporting w SharedModels wymaga zależności przez historyczny URL `xctest-dynamic-overlay` (lekcja z Fazy 1: nowy URL = konflikt tożsamości; wzorzec: `AppDatabase/Package.swift`)
- `reportIssue` w mapowaniu = fail testu bez `withKnownIssue` — ten sam commit (test-plan §6.6)

## Decyzje wyroczni (D1–D4, rozstrzygnięte przy tym planie — źródło dla testów)

- **D1**: remis same-day rozstrzyga `createdAt` (później zapisany wygrywa) — zatwierdzone jako reguła produktu
- **D2**: benchmark scaled-only → scaled JEST PR-em (`best = bestRx ?? bestScaled` — reguła produktu)
- **D3**: `isRx == nil` na benchmarku → koszyk scaled (ostrożna interpretacja; nigdy nie zawyża Rx)
- **D4**: mieszane typy — wpis o typie zgodnym z `movement.scoreType` ZAWSZE wygrywa z niezgodnym + `reportIssue`; porządek między dwoma niezgodnymi bez znaczenia (dalej remis)

## Czego NIE robimy

- Luka #7 „oznaczenie pobicia" — brak API; kandydat do iteracji 2 / S-06 backlog (wymaganie widoku FR-009)
- Luka #6 „delete cofa PR" jako test resolvera — gwarantowana konstrukcyjnie (czysta funkcja), strażnik anty-cache odłożony
- Zmian w UI/editorze (S-03/S-04 zrobią to swoimi plastrami); zmian w `PRScoreFormatter` (testowalny tylko z app targetu — kandydat dla S-03)
- Testów liczników per kategoria (FR-009 — warstwa State aplikacji, poza pakietem)

## Podejście do implementacji

Koszt × sygnał: wszystko w czystej funkcji pakietu SharedModels (`swift test`, już w CI). Najpierw charakteryzacja brzegów (tanie, zielone, zamrażają decyzje D1–D3), potem jedyna prawdziwa zmiana zachowania w TDD (czerwony test z wyrocznią D4 → minimalny kod → refactor), na końcu cookbook. Oczekiwane wartości wyłącznie jako literały z wyroczni (PRD/D1–D4) — nigdy z implementacji. Komentarze po angielsku.

## Faza 1: Brzegi wyroczni — testy dokumentujące [tryb: /10x-implement]

### Przegląd

Zamyka luki #1–#5 testami charakteryzującymi zachowanie zatwierdzone decyzjami D1–D3 + naprawia atrybucję doc-commentu.

### Wymagane zmiany:

#### 1. Nowe testy brzegowe

**Plik**: `SharedModels/Tests/SharedModelsTests/PRResolverTests.swift`

**Cel**: ~7 nowych testów: (a) `isRx == nil` na benchmarku → wpis w `bestScaled`, nie w `bestRx` [D3, luka #1]; (b) isRx true/false na ruchu bez `supportsRxScaled` → flaga ignorowana, `bestRx`/`bestScaled` nil, `best` = lepszy wynik [luka #2]; (c) remis AMRAP (równe rundy i extraReps) → nowsza data [O5, luka #3]; (d) remis time i remis reps → nowsza data [O5, luka #4]; (e) Rx-only benchmark → `bestScaled == nil`, `best == bestRx` [D2-dual, luka #5]. Zachowanie asertowane / łapana regresja / źródło / anty-wzorzec — per test w nazwie i komentarzu 1-liniowym ze źródłem (PRD linia lub D1–D3).

**Kontrakt**: fixture'y wg istniejącej konwencji suity (daty `Date(timeIntervalSince1970:)`, lepszy wynik celowo starszą datą — dyskryminacja kierunku od świeżości); literały oczekiwanych wartości; bez redundantnych kopii (jeden test per właściwość).

#### 2. Poprawka atrybucji doc-commentu

**Plik**: `SharedModels/Tests/SharedModelsTests/PRResolverTests.swift` (nagłówek suity, `:12-14`)

**Cel**: tie-break `createdAt` przestaje być podpisany jako PRD; nowe źródło: „product decision D1, plan testing-pr-correctness-all-types (2026-09-02)".

**Kontrakt**: tylko komentarz; zero zmian w testach istniejących.

### Kryteria sukcesu:

#### Automatyczna weryfikacja:

- `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test --package-path SharedModels` zielony (suita PRResolver ~21 testów)

#### Ręczna weryfikacja:

(brak)

---

## Faza 2: Mieszane typy wyniku — pełne TDD [tryb: /10x-tdd]

### Przegląd

Jedyna zmiana zachowania: wpis o typie niezgodnym z ruchem nigdy nie wygrywa z poprawnym (D4). Red → green → refactor; pauza na czerwonym teście przed dotknięciem implementacji.

### Wymagane zmiany:

#### 1. Czerwony test (PRZED implementacją)

**Plik**: `SharedModels/Tests/SharedModelsTests/PRResolverTests.swift`

**Cel**: test „wpis `.time` z nowszą datą NIE zostaje PR-em ruchu weight — zgodny typ wygrywa" [D4, luka #8] — na dziś FAILUJE (cichy remis + nowsza data). Wyrocznia: D4, nie kod. Drugi test: dwa wpisy zgodnego typu nietknięte obecną logiką (regresja porównań).

**Kontrakt**: test odwołuje się do `movement.scoreType` jako źródła zgodności; owinięty `withKnownIssue` na ścieżce reportIssue W TYM SAMYM commicie co telemetria (green).

#### 2. Minimalna implementacja + telemetria

**Plik**: `SharedModels/Sources/SharedModels/SharedModels/PRCatalog/PRResolver.swift` (+ `SharedModels/Package.swift` — zależność IssueReporting)

**Cel**: w rankingu `summary(for:entries:)` wpis o `score.scoreType == movement.scoreType` zawsze wygrywa z niezgodnym; niezgodny zgłasza `reportIssue` (id wpisu + typy). Porządek dwóch niezgodnych — bez zmian (remis). Publiczne sygnatury BEZ zmian.

**Kontrakt**: zależność w Package.swift przez URL `https://github.com/pointfreeco/xctest-dynamic-overlay` (produkt IssueReporting) — wzorzec `AppDatabase/Package.swift`; komunikaty po angielsku. Refactor po zielonym: bez zmiany zachowania.

#### 3. Deliberate-break check (mutation-lite)

**Plik**: (tymczasowa edycja `PRResolver.swift`, cofnięta)

**Cel**: celowe odwrócenie preferencji typu → suita robi się czerwona → revert. Dowód, że asercje łapią regresję (nie tylko wykonują linie) — ekwiwalent Strykera dla Swift w naszym zakresie.

**Kontrakt**: wykonane i zaraportowane w ramach fazy; żadna tymczasowa edycja nie trafia do commita.

### Kryteria sukcesu:

#### Automatyczna weryfikacja:

- Czerwony test napisany PRZED implementacją i potwierdzony failem (przebieg red udokumentowany w wyniku fazy)
- `swift test --package-path SharedModels` zielony po green+refactor (zgodny typ wygrywa, withKnownIssue na telemetrii)
- Deliberate-break: odwrócenie preferencji typu barwi suitę na czerwono (i revert przywraca zieleń)

#### Ręczna weryfikacja:

(brak)

---

## Faza 3: Cookbook i domknięcie [tryb: /10x-implement]

### Przegląd

Utrwalenie wzorca w §6 test-planu; końcowa regresja; build aplikacji po zmianie SharedModels.

### Wymagane zmiany:

#### 1. Cookbook §6

**Plik**: `context/foundation/test-plan.md`

**Cel**: notka §6.6 fazy 2 (charakteryzacja vs TDD: kiedy test dokumentujący, kiedy czerwony-najpierw; deliberate-break jako mutation-lite dla Swift; decyzje wyroczni D1–D4 jako źródło asercji); ewentualne doprecyzowanie §6.1 (reference: rozszerzona suita PRResolverTests).

**Kontrakt**: tylko §6 (§1–§5 zamrożone; statusy §3 zmienia orkiestrator).

### Kryteria sukcesu:

#### Automatyczna weryfikacja:

- `swift test --package-path SharedModels` zielony (regresja końcowa)
- §6.6 test-planu zawiera notkę fazy 2

#### Ręczna weryfikacja:

- Build aplikacji w Xcode przechodzi (SharedModels zmieniony — konsumenci resolvera nietknięci, sanity build)

---

## Strategia testowania

### Testy jednostkowe (pakiet):

- Brzegi rankingu Rx/scaled (D2/D3), remisy wszystkich typów (O5+D1), mieszane typy (D4)
- Przypadki brzegowe: isRx nil, flaga na ruchu bez wsparcia, Rx-only, równe rundy+extraReps

### Kroki testowania ręcznego:

1. Build w Xcode po fazie 3 (sanity — publiczne API bez zmian)

## Uwagi dotyczące wydajności

Brak — porównanie zyskuje jeden tani warunek typu; `reportIssue` no-op w RELEASE.

## Uwagi dotyczące migracji

Brak zmian schematu i danych. Zmiana D4 wpływa wyłącznie na ranking odczytu — wpisy w bazie nietknięte.

## Referencje

- Badania: `context/changes/testing-pr-correctness-all-types/research.md`
- Umowa jakościowa: `context/foundation/test-plan.md` (§2 ryzyko #1, §3 Faza 2)
- Wzorce: `SharedModels/Tests/SharedModelsTests/PRResolverTests.swift`, `AppDatabase/Package.swift` (IssueReporting), test-plan §6.6 (withKnownIssue)
- Konwencja commitów usera w kursie: `lesson3.2 (pK)` — przy rytuale commitów proponować w tej konwencji

## Postęp

> Konwencja: `- [ ]` oczekujące, `- [x]` wykonane. Dodaj ` — <commit sha>` po zakończeniu kroku. Nie zmieniaj tytułów kroków.

### Faza 1: Brzegi wyroczni — testy dokumentujące

#### Automatyczne

- [x] 1.1 swift test SharedModels zielony (~7 nowych testów brzegowych, luki #1–#5, atrybucja doc-commentu naprawiona) — 26ed764

### Faza 2: Mieszane typy wyniku — pełne TDD

#### Automatyczne

- [x] 2.1 Czerwony test napisany PRZED implementacją i potwierdzony failem — 8fc0e82
- [x] 2.2 swift test SharedModels zielony po green+refactor (zgodny typ wygrywa + reportIssue z withKnownIssue) — 8fc0e82
- [x] 2.3 Deliberate-break: odwrócenie preferencji typu barwi suitę na czerwono, revert przywraca zieleń — 8fc0e82

### Faza 3: Cookbook i domknięcie

#### Automatyczne

- [x] 3.1 swift test SharedModels zielony (regresja końcowa)
- [x] 3.2 §6.6 test-planu zawiera notkę fazy 2

#### Ręczne

- [x] 3.3 Build aplikacji w Xcode przechodzi
