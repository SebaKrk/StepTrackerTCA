# Test Plan

> Phased test rollout for this project. Strategy is frozen at the top
> (§1–§5); cookbook patterns at the bottom (§6) fill in as phases ship.
> Read before writing any new test.
>
> Refresh: re-run `/10x-test-plan --refresh` when stale (see §8).
>
> Last updated: 2026-09-02 (Phase 2: complete)

## 1. Strategy

Tests follow three non-negotiable principles for this project:

1. **Cost × signal.** The cheapest test that gives a real signal for the
   risk wins. Do not promote to e2e because e2e "feels safer." Do not put a
   vision model on top of a deterministic visual diff that already catches
   the regression.
2. **User concerns are first-class evidence.** Risks anchored in "the team
   is worried about X, and the failure would surface somewhere in <area>"
   carry the same weight as PRD lines or hot-spot data.
3. **Risks are scenarios, not code locations.** This plan documents *what
   could fail* and *why we believe it's likely* — drawn from documents,
   interview, and codebase *signal* (churn, structure, test base). It does
   NOT claim to know which line owns the failure. That knowledge is
   produced by `/10x-research` during each rollout phase. If the plan and
   research disagree about where the failure lives, research is the
   ground truth.

Hot-spot scope used for likelihood weighting: `WorkoutMirrorLive/`,
`SharedModels/`, `AppDatabase/`, `Commons/`, `HealthHub/`, `PeerMirror/`,
`WorkoutMirror Watch App/` (excluded: legacy `StepTrackerTCA/`, `Features/`,
`context/`, docs).

## 2. Risk Map

The top failure scenarios this project must protect against, ordered by
risk = impact × likelihood. Risks are failure scenarios in user / business
terms, not test names. The Source column cites the *evidence that surfaced
this risk* — never a specific file as "where the failure lives" (that is
research's job, see §1 principle #3).

| # | Risk (failure scenario) | Impact | Likelihood | Source (evidence — not anchor) |
|---|---|---|---|---|
| 1 | Użytkownik dobiera ciężar na sali na podstawie błędnie wyznaczonego PR (zły kierunek dla czasu, AMRAP nieleksykograficznie, scaled bije Rx, źle rozstrzygnięty remis) | High | High | PRD §Success Criteria (poprawność dla wszystkich typów), US-02; roadmap: S-03/S-04 następne w kolejce; hot-spot dir `WorkoutMirrorLive/FeaturesNew/PRBoard` (34 commits/30d) |
| 2 | Migracja bazy niszczy lub kasuje dane użytkownika na urządzeniu (logi serii, ręczne wpisy PR — bez ścieżki odzysku, sync niepodpięty) | High | Medium | interview Q1; incydent 2026-08-03 (lessons.md „Nowa migracja bazy w DEBUG kasuje dane"); PRD §Constraints (append-only, CloudKitSyncable jako furtka) |
| 3 | Wpis ginie cicho między formularzem a bazą — zapis „udaje sukces", odczyt zwraca inne wartości lub nic | High | Medium | interview Q4 („najważniejsza jest baza danych"); lessons.md („@DependencyClient gubi Data" — kompiluje się ≠ działa) |
| 4 | Wynik treningu przepada na końcu sesji — podsumowanie z zerami lub brak zapisu do HealthKit | High | Medium | interview Q1; lessons.md („session.end() zawsze", „obie ścieżki Watch-primary/iPhone-standalone"); hot-spot dir `WorkoutMirrorLive/FeaturesNew/WorkoutTab` (40 commits/30d) |
| 5 | Lista lub liczniki nie odświeżają się po zapisie/usunięciu wpisu — użytkownik widzi nieaktualny stan | Medium | High | interview Q2 („race'y, nieodświeżająca się lista"); hot-spot dirs `PRBoard` + `StatsTab` |
| 6 | Skan AI błędnie przypisuje ćwiczenia, a zamrożone dopasowania zatruwają historię przy rozszerzeniu katalogu bez bumpa wersji | Medium | Medium | interview Q2; lessons.md („wersjonowany katalog = bump + golden testy w tym samym commicie") |
| 7 | BLE nie wznawia strumienia HR po zerwaniu połączenia — uczestnik znika z Gym Room mimo działającego czytnika | Medium | Low | interview Q3 (obszar zmieniany bez pewności); lessons.md (multicast stream, bug IOS-00094-I) |

Abuse / security lens: nie dotyczy — aplikacja lokalna bez logowania,
płatności i wejścia sieciowego od osób trzecich (PRD §Access Control: bez
zmian). Jedyne niezaufane wejście to zdjęcia do skanu AI — pokryte przez
Risk #6.

### Risk Response Guidance

| Risk | What would prove protection | Must challenge | Context `/10x-research` must ground | Likely cheapest layer | Anti-pattern to avoid |
|------|-----------------------------|----------------|--------------------------------------|-----------------------|-----------------------|
| #1 | Dla każdego typu wyniku gorszy nowy wynik NIE zostaje PR-em, lepszy zostaje; scaled nigdy nie bije Rx; remis → nowsza data | „Istniejące testy resolvera pokrywają też przyszłe typy z S-03/S-04" | Gdzie rozstrzygają się kierunki porównań; jak formularz mapuje wprowadzone wartości na typ wyniku | unit (czysta funkcja, już w CI) | Problem wyroczni: oczekiwane wartości ściągnięte z implementacji; tylko happy-path „lepszy wygrywa" |
| #2 | Migrator przechodzi v1→vN na bazie Z DANYMI poprzedniej wersji i dane przeżywają migrację | „Test na pustej bazie wystarczy" (incydent dotyczył danych, nie schematu) | Jak zbudować fixture bazy vN-1 z wierszami; semantyka DEBUG erase | integration in-memory (pakiet bazy) | Asercja „nie rzuca" bez sprawdzenia, że wiersze wciąż istnieją |
| #3 | Round-trip: wpis zapisany do bazy wraca z odczytu z identycznymi wartościami; niepełne/nieznane dane nie znikają cicho | „Kompiluje się = mapuje się" | Mapowanie kolumn płaskich na typy domenowe; zachowanie przy nieznanym typie wyniku; granica pakietu: warstwa rekord+SQL testowalna w `swift test`, kontrakt klienta i reducera żyje w app targecie (research 2026-09-02) | integration in-memory (pakiet bazy — rekord+SQL) | Mockowanie bazy (test omija prawdziwe SQL); porównywanie samych identyfikatorów |
| #4 | Po zakończeniu treningu podsumowanie ma niezerowe metryki, a workout ląduje w HealthKit — na OBU ścieżkach | „Działa na jednej ścieżce = działa na obu" | Sekwencja end-flow, właściciel sesji HealthKit, punkty synchronizacji między ścieżkami | manual smoke wg skryptu (e2e HealthKit wykluczone — §7) | Zamrażanie przepływów TCA testami w trakcie fazy twórczej (interview Q4) |
| #5 | Po zapisie/usunięciu wpisu lista i liczniki pokazują nowy stan bez restartu aplikacji | „Warstwa odczytu zawsze sama odświeża" | Jak zmiany propagują się z bazy do widoków; co czyta pola, a co tylko tożsamość kolekcji | manual smoke + istniejący test przepływu delete | Snapshot testy UI (§7) |
| #6 | Znane nazwy z realnych skanów dają oczekiwane przypisanie; rozszerzenie katalogu = bump wersji + golden case w tym samym commicie | „Nowy alias niczego nie psuje" (wyniki dopasowań zamrożone w bazie) | Czy istniejące golden testy pokrywają realne błędne przypadki z wywiadu Q2 | unit golden (suita istnieje, rozszerzać) | Poprawka matchera bez dopisania golden case'a |
| #7 | Po zerwaniu połączenia znany host odzyskuje strumień bez restartu; drugi subskrybent też dostaje eventy | „Działa przy pierwszym połączeniu = działa po reconnect" | Maszyna stanów reconnect; kształt multicastu strumieni | unit na maszynie stanów (bez sprzętu) | Testy wymagające fizycznego czytnika w CI |

## 3. Phased Rollout

Each row is a discrete rollout phase that will open its own change folder
via `/10x-new`. Status moves left-to-right through the values below; the
orchestrator updates Status as artifacts appear on disk.

| # | Phase name | Goal (one line) | Risks covered | Test types | Status | Change folder |
|---|---|---|---|---|---|---|
| 1 | Siatka bezpieczeństwa bazy | Dane użytkownika przeżywają migracje i zapisy (migrator z danymi + round-trip rekordów) | #2, #3 | integration in-memory | complete | context/changes/testing-database-safety-net/ |
| 2 | Poprawność PR wszystkich typów | Kierunki/remisy/Rx-scaled odporne na zmiany z S-03/S-04 — testy jako specyfikacja PRZED implementacją (TDD) | #1 | unit (czysta funkcja) | complete | context/changes/testing-pr-correctness-all-types/ |
| 3 | Golden testy katalogu AI | Realne błędne przypisania zamienione w golden case'y; rytuał bump+golden egzekwowany | #6 | unit golden | not started | — |
| 4 | Bramki jakości i smoke | Dolna granica zablokowana: co musi być zielone przed merge; manualne smoke skodyfikowane w §6 | #4, #5, #7 | gates + manual smoke scripts | not started | — |

## 4. Stack

The classic test base for this project. Test-base profile: **sparse** —
8 plików testowych (6 w SharedModels, 1 w AppDatabase, 1 w targecie
aplikacji); logika czysta dobrze pokryta, warstwa feature'ów prawie pusta
(celowo — patrz §7).

| Layer | Tool | Version | Notes |
|---|---|---|---|
| unit + integration (pakiety SPM) | Swift Testing (`swift test`) | Swift 6 toolchain | lokalnie wymaga `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer` (xcode-select wskazuje CommandLineTools) |
| testy przepływów aplikacji | Swift Testing + TCA TestStore (target WorkoutMirrorLiveTests, host WorkoutMirrorLive) | TCA 1.26 | uruchamiane tylko w Xcode (Cmd+U); poza CI |
| e2e | none — deliberately | — | patrz §7 (bez e2e HealthKit na symulatorze) |
| AI-native | none w MVP | — | brak uzasadnienia koszt × sygnał przy lokalnej aplikacji mobilnej |

**Stack grounding tools (current session):**
- Docs: none — Context7/dokumentacyjne MCP niedostępne w tej sesji; oparto na lokalnych manifestach i konfiguracji CI; checked: 2026-09-02
- Search: wbudowany WebSearch dostępny — nieużyty (stos znany z lokalnych źródeł); checked: 2026-09-02
- Runtime/browser: none — nie dotyczy (aplikacja natywna iOS); checked: 2026-09-02
- Provider/platform: GitHub (publiczne API + gh CLI po zalogowaniu) — istotne dla bramek CI; checked: 2026-09-02

## 5. Quality Gates

The full set of gates that must pass before a change reaches production.
"Required after §3 Phase <N>" means the gate is enforced once that rollout
phase lands; before that, the gate is `planned`.

| Gate | Where | Required? | Catches |
|---|---|---|---|
| build aplikacji (xcodebuild, wykonuje użytkownik) | local | required | błędy kompilacji, rozjazd projektu |
| swift test pakietów (matrix SharedModels + AppDatabase) | local + CI (push/PR na develop, release) | required | regresje logiki czystej i warstwy bazy |
| testy przepływów aplikacji (Cmd+U) | local | required after §3 Phase 2 | regresje przepływów TCA objętych testami |
| golden testy katalogu | local + CI (w suicie pakietowej) | required after §3 Phase 3 | ciche regresje dopasowań AI |
| manual smoke wg skryptów (end-flow, odświeżanie list) | przed testem polowym / TestFlight | recommended after §3 Phase 4 | awarie end-to-end poza zasięgiem warstw tańszych |

## 6. Cookbook Patterns

How to add new tests in this project. Each sub-section is filled in once
the relevant rollout phase ships; before that, the sub-section reads
"TBD — see §3 Phase <N>."

### 6.1 Adding a unit test to an SPM package

- **Location**: `<pakiet>/Tests/<pakiet>Tests/` obok testowanej logiki.
- **Naming**: `<Obszar>Tests.swift`, `@Suite` + `@Test` (Swift Testing).
- **Reference test**: `SharedModels/Tests/SharedModelsTests/PRResolverTests.swift`.
- **Fixtures**: daty z `Date(timeIntervalSince1970:)`, nigdy `.now` (lessons.md).
- **Run locally**: `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test --package-path <pakiet>`.

### 6.2 Adding a database integration test

- **Location**: `AppDatabase/Tests/AppDatabaseTests/`.
- **Pattern**: in-memory `DatabaseQueue()` + `AppDatabaseSchema.makeMigrator().migrate(db)`; round-trip = insert przez `Record.insert { record }.execute(db)` → `Record.all.fetchAll(db)` → `toDomain()` → równość WSZYSTKICH pól z literałami (nie samych id). Fixture starej wersji schematu: `migrate(db, upTo: "vN_...")` + INSERT surowym SQL (struktury `@Table` mapują najnowszy schemat — nie używać ich do starych wersji).
- **Pułapki**: daty w surowym SQL w formacie `YYYY-MM-DD HH:MM:SS` (nie ISO-8601 z `Z`); fixture'y dat z `Date(timeIntervalSince1970:)` (pełne sekundy); testy stratnych przejść owijać `withKnownIssue` (mapowania zgłaszają `reportIssue`).
- **Reference tests**: `MigratorTests.swift` (migrator z danymi, predykat erase), `PREntryRecordRoundTripTests.swift` (round-trip + defensive-nil), `RecordRoundTripTests.swift` (komplet rekordów, kontrakt throws).
- **Run locally**: `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test --package-path AppDatabase`.

### 6.3 Adding a TCA flow test (TestStore)

- **Location**: `WorkoutMirrorLiveTests/` (host: WorkoutMirrorLive, tylko Cmd+U).
- **Reference test**: `WorkoutMirrorLiveTests/PREntryEditorFeatureTests.swift` (withDependencies, LockIsolated jako spy, DismissEffect).
- **Kiedy pisać**: tylko dla przepływów uznanych za stabilne — nie betonować przepływów w fazie twórczej (§7).

### 6.4 Adding a golden test for the AI exercise catalog

- TBD — see §3 Phase 3 (zalążek: `SharedModels/Tests/SharedModelsTests/ExerciseTypeMatchingTests.swift`; reguła: rozszerzenie katalogu = bump wersji + golden case w tym samym commicie).

### 6.5 Adding a manual smoke script

- TBD — see §3 Phase 4 (istniejący punkt wyjścia: manualne skrypty testowe w `StepTrackerTCA/PLANS/`, lokalne).

### 6.6 Per-rollout-phase notes

- **Phase 1 (2026-09-02)**: dodanie `reportIssue` do mapowań rekordów wymaga aktualizacji testów defensywnych o `withKnownIssue` w tym samym commicie (zgłoszony issue = fail w Swift Testing). Zależność IssueReporting w Package.swift deklarować przez historyczny URL `xctest-dynamic-overlay` (nowy URL `swift-issue-reporting` = konflikt tożsamości pakietu z pinem tranzytywnym). SQLiteData przechowuje daty jako TEXT `YYYY-MM-DD HH:MM:SS` — fixture'y surowego SQL z ISO-8601 `Z` nie parsują się przy odczycie.
- **Phase 2 (2026-09-02)**: dwa tryby dodawania testów logiki — **charakteryzacja** (zachowanie już poprawne: test dokumentujący, zielony od razu, źródło asercji = PRD lub decyzja wyroczni D1–D4 z planu `testing-pr-correctness-all-types`) vs **TDD** (zmiana zachowania: czerwony test nazwany jednym zdaniem PRZED kodem — wzorzec `mismatchedTypeNeverWins` w PRResolverTests). Gdy PRD nie rozstrzyga brzegu — decyzja usera zapisana w planie staje się formalnym źródłem wyroczni; nie podpisywać wyborów implementacyjnych jako PRD. Mutation-lite dla Swift: deliberate-break (celowe odwrócenie warunku → suita musi być czerwona → revert) zamiast Strykera.

## 7. What We Deliberately Don't Test

Exclusions agreed during the rollout (Phase 2 interview, Q5). Future
contributors should respect these unless the underlying assumption changes.

- **Snapshot testy widoków** — UI zmienia się co tydzień; psułyby się bez sygnału. Re-evaluate po stabilizacji designu. (Source: interview Q5.)
- **Legacy targety (StepTrackerTCA, stara Watch App)** — przeznaczone do kasacji; żadnych testów, żadnych zmian. (Source: interview Q5.)
- **E2E z HealthKit na symulatorze** — drogi setup, wątpliwy sygnał; krytyczne przepływy chronione manualnym smoke (§3 Phase 4). (Source: interview Q5.)
- **Betonowanie przepływów TCA w fazie twórczej** — reducery/UI świadomie w procesie twórczym; testy przepływów tylko dla ustabilizowanych obszarów. Re-evaluate per obszar przy jego stabilizacji. (Source: interview Q4.)
- **BLE z fizycznym sprzętem w CI** — niewykonalne bez urządzeń; warstwa chroniona unit testami maszyn stanów + manualnie. (Source: interview Q3.)

## 8. Freshness Ledger

- Strategy (§1–§5) last reviewed: 2026-09-02
- Stack versions last verified: 2026-09-02
- AI-native tool references last verified: 2026-09-02

Refresh (`/10x-test-plan --refresh`) when:

- a new top-3 risk surfaces from the roadmap or archive,
- a recommended tool's `checked:` date is older than three months,
- the project's tech stack changes (new framework, new test runner),
- §7 negative-space no longer matches what the team believes.
