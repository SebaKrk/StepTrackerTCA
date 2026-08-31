---
project: "MyFitnessJournal — Tablica PR (PR Board)"
version: 1
status: draft
created: 2026-08-30
updated: 2026-08-31
prd_version: 1
main_goal: speed
top_blocker: time
milestone_id: pr-board-mvp
milestone_seq: 1
milestone_status: open
---

# Roadmap: MyFitnessJournal — Tablica PR (PR Board)

> Wyprowadzona z `context/foundation/prd.md` (v1) + auto-zbadanej bazy kodu.
> Edycja w miejscu; archiwizacja przy zastąpieniu.
> Plastry poniżej wypisane w porządku zależności. Tabela "At a glance" jest indeksem.

## Milestone

**M-1: Tablica PR — MVP** — Status: open

- **Intent:** Trenujący prowadzi swoje rekordy życiowe w aplikacji zamiast w notesie: przegląda katalog ruchów, zapisuje wyniki z metadanymi i widzi poprawnie wyznaczony aktualny PR — bez regresji istniejących przepływów.
- **Source materials:** `context/foundation/prd.md` (v1)
- **Done when:** każdy F-NN i S-NN poniżej ma status `done`.
- **Scope anchors:** FR-001, FR-002, FR-004–FR-007, FR-009–FR-012; US-01, US-02. (FR-008 zaparkowane — miły dodatek poza ścieżką krytyczną; FR-003 przeniesione do iteracji 2 już na etapie PRD.)

## Vision recap

System rejestruje treningi i logi serii, ale nie ma miejsca, gdzie rekordy życiowe są zebrane, porównywalne w czasie i opisane metadanymi (Rx/scaled, sprzęt, kontekst) — dziś pełni je notes papierowy albo pamięć. Tablica PR domyka warstwę po-treningową: nowy ekran za przyciskiem w segmencie Ćwiczenia zakładki Statystyki, addytywny wobec istniejących przepływów.

## North star

**S-02: Użytkownik zapisuje wynik i widzi zaktualizowany PR** — to dosłownie główne kryterium sukcesu PRD (kategoria → ruch → wpis z metadanymi → PR na szczególe i w licznikach) i najmniejszy przepływ przecinający wszystkie warstwy naraz; przy celu `speed` jego wczesne dowiezienie decyduje o wszystkim dalej.

> Gwiazda przewodnia (north star) to najmniejszy plaster end-to-end, którego dowiezienie
> udowadnia główną hipotezę produktu — stoi tak wcześnie, jak pozwalają jego
> wymagania wstępne, bo wszystko inne ma sens dopiero, gdy on działa.

## At a glance

| ID   | Change ID                      | Outcome (użytkownik może…)                                  | Prerequisites | PRD refs                                | Status   |
| ---- | ------------------------------ | ----------------------------------------------------------- | ------------- | --------------------------------------- | -------- |
| F-01 | shared-result-input-components | (fundament) kontrolki wyników dostępne poza podsumowaniem   | —             | FR-005                                  | done |
| S-01 | pr-board-entry-and-catalog     | otworzyć Tablicę PR i przeglądać katalog ruchów             | —             | FR-001, FR-002, FR-010, FR-011, FR-009  | done |
| S-02 | record-entry-current-pr        | zapisać wynik z metadanymi i zobaczyć zaktualizowany PR     | S-01, F-01    | US-01, FR-004, FR-005, FR-007, FR-009, FR-012 | proposed |
| S-03 | all-score-types-controls       | zapisać czas / powtórzenia / AMRAP dedykowanymi kontrolkami | S-02, F-01    | FR-005, FR-007                          | proposed |
| S-04 | rx-scaled-split                | porównać osobne PR-y Rx i Scaled na benchmarku              | S-03          | US-02, FR-007                           | proposed |
| S-05 | delete-entry-recompute         | usunąć wpis, a PR przelicza się automatycznie               | S-02          | FR-006, FR-007                          | proposed |
| S-06 | progress-views-polish          | śledzić postęp: wykres, historia, krotność masy ciała       | S-02          | FR-009, US-01                           | proposed |

## Baseline

Co już stoi w kodzie na `2026-08-30` (auto-zbadane + potwierdzone przez użytkownika).
Fundamenty poniżej zakładają obecność tych warstw i NIE budują ich ponownie.

- **UI / nawigacja:** present — zakładka Statystyki z 3 segmentami i toolbar zadeklarowany raz dla zakładki (`WorkoutMirrorLive/FeaturesNew/StatsTab/StatsView.swift:52`; crown :103, AI :83, profil :87; segmenty :151)
- **Dane:** present — migracje append-only v1→v11, ostatnia `v11_classParticipation` (`AppDatabase/Sources/AppDatabase/Schema.swift:313`)
- **Katalog ćwiczeń:** present — `ExerciseType` z `catalogVersion == 6`, aliasami i mechanizmem re-match (`SharedModels/.../ExerciseType.swift:551`, matcher :559)
- **Profil / masa ciała:** present — `PersonalDataClient` z odczytem masy ciała (`.../PersonSettings/Client/PersonalDataClient.swift:12`, getWeight :17)
- **Komponenty wejściowe wyników:** partial — kontrolki czasu/powtórzeń/rund istnieją, ale są feature-scoped wewnątrz podsumowania (`.../Summary/Components/`), wszystkie internal, nic w warstwie współdzielonej
- **Backend / API, Auth:** nie dotyczy z definicji — aplikacja lokalna bez logowania (PRD: Access Control bez zmian)
- **Deploy / CI:** present — workflow CI uruchamiający testy pakietów (`.github/workflows/ci.yml`)

## Foundations

### F-01: Współdzielone kontrolki wyników

- **Outcome:** (fundament) kontrolki wpisywania wyników (czas mm:ss, powtórzenia, rundy+powtórzenia, edycja wartości) dostępne z warstwy współdzielonej; ekran podsumowania konsumuje je z nowego miejsca bez zmiany zachowania.
- **Change ID:** shared-result-input-components
- **PRD refs:** FR-005 (nota kosztowa: "to przenosiny, nie import — ująć jako osobną fazę")
- **Unlocks:** S-02, S-03 (formularz wpisu bez tych kontrolek nie powstanie zgodnie z FR-005 — "bez parsowania tekstu")
- **Prerequisites:** —
- **Parallel with:** S-01
- **Blockers:** —
- **Unknowns:** —
- **Risk:** dotyka świeżo przebudowanego ekranu podsumowania — czyste przenosiny bez zmiany zachowania, sekwencjonowane wcześnie, bo blokują gwiazdę przewodnią; guardrail PRD: istniejące przepływy bez regresji.
- **Status:** done

## Slices

### S-01: Wejście do Tablicy i przeglądanie katalogu

- **Outcome:** użytkownik może otworzyć Tablicę PR przyciskiem w segmencie Ćwiczenia (globalne przyciski toolbara ukryte tylko w tym segmencie) i przeglądać katalog ~25–30 ruchów w 5 kategoriach z podgrupami i notą standardu Rx przy benchmarkach; ruchy bez wpisów wyszarzone, ale widoczne; segmenty Dziś/Analityka bez zmian, przełączanie bez migotania toolbara.
- **Change ID:** pr-board-entry-and-catalog
- **PRD refs:** FR-001, FR-002 (katalog statyczny z uśpionymi mostkami), FR-010, FR-011 (zachowane), FR-009 (ekran kategorii i lista ruchów — stany puste)
- **Prerequisites:** —
- **Parallel with:** F-01
- **Blockers:** —
- **Unknowns:** —
- **Risk:** jedyna modyfikacja istniejącego UI w całym module (warunek widoczności toolbara) — sekwencjonowana pierwsza, żeby ewentualną regresję toolbara wykryć od razu, a nie pod koniec terminu.
- **Status:** done

### S-02: Zapis wpisu i aktualny PR (gwiazda przewodnia)

- **Outcome:** użytkownik może zapisać wynik ciężarowy z pełnymi metadanymi (data, Rx/scaled gdzie wspierane, sprzęt, kontekst, RPE, notatka; masa ciała dopisana automatycznie jako snapshot) i natychmiast zobaczyć zaktualizowany PR na szczególe ruchu oraz rosnący licznik kategorii; wpis trwały między uruchomieniami, PR wyliczany z historii (nie zapisany osobno).
- **Change ID:** record-entry-current-pr
- **PRD refs:** US-01, FR-004, FR-005 (kontrolka wartości ciężarowej), FR-007 (rdzeń czystej funkcji: kierunek "więcej = lepiej", remis → nowsza data), FR-009 (szczegół ruchu — duża wartość PR; licznik kategorii), FR-012 (zachowane — wyłącznie nowe tabele w kolejnej migracji append-only)
- **Prerequisites:** S-01, F-01
- **Parallel with:** —
- **Blockers:** —
- **Unknowns:**
  - Copy rozróżniające "PR sesji" (istniejące oznaczenie w analityce) od "rekordu życiowego" (Tablica) — Owner: użytkownik. Block: no (rozstrzygnięcie przy planie UI tego plastra).
- **Risk:** najszerszy pionowy przekrój (nowe tabele + czysta funkcja + formularz + szczegół) — celowo wcześnie jako walidacja całości; uwaga operacyjna z PRD: konfiguracja deweloperska czyści bazę przy zmianie schematu — zaplanować moment migracji/backup na urządzeniu dev.
- **Status:** proposed

### S-03: Wszystkie typy wyników z dedykowanymi kontrolkami

- **Outcome:** użytkownik może zapisać wynik czasowy (mm:ss, "mniej = lepiej"), powtórzeniowy (stepper) i AMRAP (rundy + powtórzenia, porównanie leksykograficzne) — z walidacją i nieaktywnym przyciskiem zapisu przy niepoprawnej wartości; PR wyznaczany poprawnie dla każdego typu.
- **Change ID:** all-score-types-controls
- **PRD refs:** FR-005, FR-007 (kierunki per typ wyniku, AMRAP leksykograficznie)
- **Prerequisites:** S-02, F-01
- **Parallel with:** S-05, S-06
- **Blockers:** —
- **Unknowns:** —
- **Risk:** domyka kryterium sukcesu "poprawność dla wszystkich typów wyniku potwierdzona testami czystej funkcji" — trzymane tuż za gwiazdą, bo bez typów czasowych benchmarki (S-04) nie istnieją.
- **Status:** proposed

### S-04: Rozdział Rx / Scaled na benchmarkach

- **Outcome:** użytkownik może porównać dwa osobne PR-y na benchmarku — Rx i Scaled obok siebie z badge'ami (scenariusz US-02: Fran 8:10 Rx obok 6:30 scaled; wynik scaled nigdy nie bije Rx mimo lepszego czasu).
- **Change ID:** rx-scaled-split
- **PRD refs:** US-02, FR-007 (osobne PR-y Rx i scaled)
- **Prerequisites:** S-03
- **Parallel with:** S-05, S-06
- **Blockers:** —
- **Unknowns:** —
- **Risk:** benchmarki są głównie czasowe, więc plaster stoi za S-03; logika rozdziału mieszka w tej samej czystej funkcji — ryzyko regresu wyników z S-02/S-03 łapią istniejące testy funkcji.
- **Status:** proposed

### S-05: Usunięcie wpisu z automatycznym przeliczeniem

- **Outcome:** użytkownik może usunąć wpis (swipe z potwierdzeniem), a aktualny PR i liczniki kategorii samoczynnie wracają do poprzedniego stanu — własność wynikająca z PR-a liczonego z historii.
- **Change ID:** delete-entry-recompute
- **PRD refs:** FR-006, FR-007 (usunięcie wpisu cofa PR — kryterium akceptacji US-01)
- **Prerequisites:** S-02
- **Parallel with:** S-03, S-04, S-06
- **Blockers:** —
- **Unknowns:** —
- **Risk:** mały plaster domykający pętlę CRUD; twarde usunięcie z potwierdzeniem to świadoma decyzja PRD (soft-delete odrzucony bez dowodu potrzeby) — potwierdzenie jest częścią kryterium.
- **Status:** proposed

### S-06: Postęp i dopełnienie widoków

- **Outcome:** użytkownik może śledzić postęp ruchu: wykres od 2+ wpisów (oś odwrócona dla czasu), historia malejąco po dacie, ikona sprzętu, krotność masy ciała dla ruchów ciężarowych; ekran kategorii pokazuje datę ostatniego PR, a listy ruchów aktualny PR z względną datą.
- **Change ID:** progress-views-polish
- **PRD refs:** FR-009, US-01 (Then: ikona sprzętu, krotność masy ciała)
- **Prerequisites:** S-02
- **Parallel with:** S-03, S-04, S-05
- **Blockers:** —
- **Unknowns:**
  - Zobowiązania dostępności (Dynamic Type XXL, VoiceOver z jednostkami) — potwierdzić rezygnację lub przywrócić przy planie UI. Owner: użytkownik. Block: no.
- **Risk:** guardrail PRD: liczniki i PR liczone z pełnej historii nie mogą blokować UI — plaster z największą powierzchnią prezentacyjną, ale zerową nową logiką domenową, więc bezpieczny na koniec ścieżki.
- **Status:** proposed

## Backlog Handoff

| Roadmap ID | Change ID                      | Suggested issue title                                | Ready for `/10x-plan` | Notes                              |
| ---------- | ------------------------------ | ---------------------------------------------------- | --------------------- | ---------------------------------- |
| F-01       | shared-result-input-components | Wydziel kontrolki wyników do warstwy współdzielonej  | yes                   | Run `/10x-plan shared-result-input-components` |
| S-01       | pr-board-entry-and-catalog     | Tablica PR: wejście z segmentu Ćwiczenia + katalog    | yes                   | Run `/10x-plan pr-board-entry-and-catalog` |
| S-02       | record-entry-current-pr        | Tablica PR: zapis wpisu i wyznaczanie aktualnego PR   | no                    | Czeka na S-01, F-01                |
| S-03       | all-score-types-controls       | Tablica PR: typy wyników czas/powtórzenia/AMRAP       | no                    | Czeka na S-02                      |
| S-04       | rx-scaled-split                | Tablica PR: osobne PR-y Rx i Scaled                   | no                    | Czeka na S-03                      |
| S-05       | delete-entry-recompute         | Tablica PR: usuwanie wpisu z przeliczeniem PR         | no                    | Czeka na S-02                      |
| S-06       | progress-views-polish          | Tablica PR: wykres postępu i dopełnienie widoków      | no                    | Czeka na S-02                      |

## Open Roadmap Questions

1. **Estymata 1RM (formuła Epleya) z historii serii przez most do katalogu ćwiczeń** — czy wchodzi kiedykolwiek, a jeśli tak: iteracja 2 czy później? Owner: użytkownik. Block: żaden plaster (decyzja iteracji 2).
2. **Dostępność (Dynamic Type XXL, VoiceOver z jednostkami)** — potwierdzić świadomą rezygnację lub przywrócić jako zobowiązanie. Owner: użytkownik. Block: nie blokuje planowania; dotyczy planów UI S-02/S-03/S-06.
3. **Dwa pojęcia "PR" w segmencie Ćwiczenia** (oznaczenie PR z logów serii w analityce vs rekord życiowy z Tablicy — wartości mogą się rozjeżdżać) — rozróżnienie w copy lub jednostronny mostek w iteracji 2. Owner: użytkownik. Block: copy ekranów S-02/S-06 (do rozstrzygnięcia najpóźniej przy ich planach UI).

## Parked

- **CrossFit Total (FR-008)** — Why parked: priorytet "miły dodatek" poza ścieżką krytyczną; przy celu `speed` i twardym terminie wraca tylko, jeśli zostanie czas po S-06.
- **Analiza proporcji między bojami** — Why parked: PRD §Non-Goals 1; grunt (czysta funkcja PR, snapshot masy ciała) przygotowany w S-02.
- **Ranking społecznościowy / Gym Room** — Why parked: PRD §Non-Goals 2 — poza domeną osobistej tablicy.
- **Import z zewnętrznych aplikacji** — Why parked: PRD §Non-Goals 3 — nieweryfikowalne dane wejściowe.
- **Powiadomienia "czas na retest"** — Why parked: PRD §Non-Goals 4 — wartość niepotwierdzona.
- **Współdzielenie danych PR z widgetami/Watch** — Why parked: PRD §Non-Goals 5 — decyzja: niepotrzebne.
- **Auto-detekcja benchmarków w skanie + auto-dopis wyników** — Why parked: PRD §Non-Goals 6 — iteracja 2; mosty w katalogu (S-01) już na to gotowe.
- **Własne ruchy użytkownika** — Why parked: PRD §Non-Goals 7 — iteracja 2 (ryzyko duplikatów, termin).
- **Pełny katalog ~60 ruchów** — Why parked: PRD §Non-Goals 8 — rozszerzenie z użycia.
- **Konwersja jednostek na funty** — Why parked: PRD §Non-Goals 9 — kg/metry na sztywno w modelu.
- **Wynik cappowany / DNF w benchmarkach** — Why parked: PRD §Non-Goals 10 — świadoma luka; obejście: zapis jako scaled z notatką.

## Milestone History

(Puste — pierwszy milestone projektu.)

## Done

- **F-01: (fundament) kontrolki wpisywania wyników (czas mm:ss, powtórzenia, rundy+powtórzenia, edycja wartości) dostępne z warstwy współdzielonej; ekran podsumowania konsumuje je z nowego miejsca bez zmiany zachowania.** — Archived 2026-08-31 → `context/archive/2026-08-30-shared-result-input-components/`. Lesson: —.
- **S-01: użytkownik może otworzyć Tablicę PR przyciskiem w segmencie Ćwiczenia i przeglądać katalog 29 ruchów w 5 kategoriach z podgrupami i notą standardu Rx przy benchmarkach; ruchy bez wpisów wyszarzone, ale klikalne.** — Archived 2026-08-31 → `context/archive/2026-08-31-pr-board-entry-and-catalog/`. Lesson: —.
