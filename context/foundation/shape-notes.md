---
project: "MyFitnessJournal — Tablica PR (PR Board)"
context_type: brownfield
created: 2026-08-27
updated: 2026-08-27
checkpoint:
  current_phase: 8
  phases_completed: [1, 2, 3, 4, 5, 6, 7]
  gray_areas_resolved:
    - topic: "kategoria zmiany"
      decision: "nowy moduł: Tablica PR w segmencie Ćwiczenia zakładki Statystyki (Statystyki → Ćwiczenia → Tablica PR)"
    - topic: "zakres głównej persony"
      decision: "trenujący siłowo/CrossFit z zapisaną historią treningów w aplikacji (właściciel + testerzy TestFlight)"
    - topic: "wgląd — czemu teraz"
      decision: "dotąd priorytet miały funkcje live (sesje, mirroring Watch, GymRoom); warstwa po-treningowa dojrzała do rozbudowy"
    - topic: "model dostępu"
      decision: "bez zmian — lokalny profil na urządzeniu, bez logowania i ról"
    - topic: "harmonogram"
      decision: "max 2 tygodnie pracy po godzinach; twardy termin: 2026-09-07"
    - topic: "App Group / widget / Watch"
      decision: "poza zakresem całkowicie — dane PR nie są współdzielone z rozszerzeniami; baza zostaje w Application Support (decyzja użytkownika: nie ma takiej potrzeby)"
    - topic: "katalog ruchów vs istniejący ExerciseType"
      decision: "osobny katalog PRMovement jako STATYCZNA TABLICA SWIFT w SharedModels (runda Sokratesa uchyliła JSON z bundla: drugi mechanizm katalogowy + loader bez realnej korzyści), z mostkiem: opcjonalne pole exerciseType per ruch + wodAliases benchmarków — umożliwia przyszłą auto-detekcję w skanie i auto-dopis wyników"
    - topic: "rozmiar katalogu startowego"
      decision: "ścięty rdzeń ~25–30 ruchów (najczęstsze boje + top benchmarki) zamiast pełnych ~60 ze spec; reszta dojdzie z użycia (runda Sokratesa: katalog-cmentarz vs 2-tygodniowy termin)"
    - topic: "auto-detekcja benchmarków w skanie AI + auto-dopis wyniku do Tablicy"
      decision: "następna iteracja (grunt: aliasy benchmarków w katalogu już teraz); MVP = wpisy ręczne"
    - topic: "warstwa techniczna"
      decision: "konwencje repo ponad literą spec: SQLiteData + migracja v12 (nie GRDB/SwiftData), nawigacja @Presents/sheet jak w StatsTab (nie StackState)"
  frs_drafted: 12
  quality_check_status: accepted
---

# Shape notes — Tablica PR (PR Board)

Notatki wejściowe: szczegółowa specyfikacja użytkownika „Tablica PR — specyfikacja dla agenta"
(model danych, katalog ruchów w 5 kategoriach, reguły PR, warstwy, etapy 1–5) + wcześniejszy szkic
`PLANS/IOS-00127-personal-records.md` (wariant 1 — zastąpiony tą specyfikacją; auto-derywacja → Open Questions).
Rekonesans istniejącej implementacji wykonany (toolbar StatsView, SQLiteData/Schema v1–v11,
PersonalDataClient/HealthKit bodyMass, ExerciseType v6, brak benchmarków w aktywnym kodzie).

## Current System

- Cel systemu: aplikacja iOS/watchOS do prowadzenia i analizy treningów siłowych/CrossFit.
- Architektura: aplikacja natywna z lokalnymi pakietami SPM (SharedModels, HealthHub, AppDatabase, PeerMirror, Commons); wzorzec TCA + "głupie" widoki SwiftUI; nawigacja przez @Presents/sheet/fullScreenCover (bez StackState).
- Stos: Swift 6, SwiftUI, The Composable Architecture, SQLiteData (migracje v1–v11, append-only, baza w Application Support), HealthKit, WatchConnectivity, CoreBluetooth, iOS 26+ (Liquid Glass).
- Użytkownicy dziś: właściciel aplikacji + testerzy TestFlight; trening siłowy/CrossFit.
- Kluczowa funkcjonalność dziś: sesje treningowe live (dwie ścieżki: Watch-primary / iPhone-standalone), plany ze skanem AI (ekstrakcja ćwiczeń + wodName), logi serii (ExerciseLogRecord: actualWeight kg, setsData z typowanym reps, scaling rx/scaled, isPR), podsumowania, analityka ćwiczeń (segment Ćwiczenia w zakładce Statystyki), katalog ExerciseType v6 z aliasami i mechanizmem re-match.
- Miejsce zabudowy: zakładka Statystyki ma 3 segmenty (Dziś / Analityka / Ćwiczenia); toolbar (crown, AI, profil) zadeklarowany raz dla całej zakładki (StatsView.swift), obowiązuje we wszystkich segmentach.

## Vision & Problem Statement

Ból: trenujący zna swoje rekordy życiowe (1RM, czasy benchmarków, max powtórzeń) z notesu albo z głowy — na sali potrzebuje ich natychmiast do doboru obciążeń, oceny progresu i porównania wyników WOD-ów.
Luka w systemie: aplikacja rejestruje treningi i logi serii, ale nie ma miejsca, gdzie rekordy życiowe są zebrane, porównywalne w czasie i opisane metadanymi (Rx/scaled, sprzęt, kontekst) — bez tego postęp po roku jest nieweryfikowalny.
Czemu teraz: warstwa po-treningowa (podsumowania, analityka) dojrzała; profil zawodnika (biometria, RHR, HRV, gotowość) istnieje — Tablica PR jest naturalnym rozszerzeniem statystyk, nie duplikuje profilu.
Obecne obejście i koszt: notes/pamięć — brak dat, brak rozróżnienia Rx/scaled i sprzętu, zero powiązania z historią.

## User & Persona

Główna persona: osoba trenująca siłowo/CrossFit z zapisaną historią treningów w MyFitnessJournal — właściciel aplikacji i testerzy TestFlight. Moment: na sali przy doborze obciążenia i po treningu przy zapisie/ocenie wyniku; przy benchmarkach — porównanie z poprzednim podejściem (Rx vs scaled).
Zmiana dla istniejących użytkowników: addytywna — nowy ekran za nowym przyciskiem w segmencie Ćwiczenia; jedyna widoczna modyfikacja istniejącego UI: w segmencie Ćwiczenia globalne przyciski toolbar (crown/AI/profil) ustępują miejsca przyciskowi Tablicy PR.

## Access Control

Obecny model: aplikacja lokalna, bez logowania i ról — profil użytkownika na urządzeniu (PersonSettings), dane w lokalnym SQLite + HealthKit za zgodami systemowymi.
Brak planowanych zmian — obecny model zachowany. Nowy ekran dziedziczy model dostępu aplikacji.

## MVP delta flow (zablokowany, wersja 2 — po specyfikacji Tablicy PR)

1. Użytkownik otwiera Statystyki → segment Ćwiczenia → przycisk „Tablica PR" w toolbarze (globalne przyciski crown/AI/profil ukryte w tym segmencie).
2. Widzi 5 kart kategorii (Olimpijskie, Siła, Gimnastyka, Kondycja, Benchmarki — stała kolejność) z licznikami „uzupełnione/wszystkie" i datą ostatniego PR.
3. Wchodzi w kategorię → lista ruchów w podgrupach; ruchy bez wpisu wyszarzone, ale widoczne.
4. Wchodzi w ruch → aktualny PR (Rx i scaled osobno, gdzie dotyczy), wykres postępu, historia wpisów.
5. Dodaje wpis (formularz per typ wyniku: kg / mm:ss / powtórzenia / rundy+powt. / metry / kcal / cm deficytu) z metadanymi: data, Rx/scaled, sprzęt, kontekst (fresh/inWod/competition), RPE, notatka; masa ciała dopisuje się sama jako snapshot z HealthKit.
6. PR przelicza się automatycznie (czysta funkcja z historii) — widok ruchu i liczniki kategorii aktualizują się.

Harmonogram: max 2 tygodnie pracy po godzinach, twardy termin: początek września 2026 (deklaracja użytkownika); zakres = Etapy 1–4 specyfikacji (model+katalog, logika PR, reducery, UI). Ścięty katalog startowy (~25–30 ruchów) wspiera ten termin.

## Success Criteria

### Primary
- Użytkownik przechodzi pełny przepływ: kategoria → ruch → wpis z metadanymi → zaktualizowany PR widoczny na szczególe ruchu i w licznikach kategorii.
- Wyznaczanie PR jest poprawne dla wszystkich typów wyniku (w tym kierunek „mniej = lepiej" dla czasu, leksykograficzne AMRAP, rozdział Rx/scaled, remis → nowsza data) — potwierdzone testami czystej funkcji.

### Secondary
- Notes zostaje w szafce: na sali użytkownik sięga po aplikację zamiast po notes/pamięć (obserwowalny sygnał, że moduł zastąpił obejście).

### Guardrails
- Istniejące przepływy (sesje live, plany, podsumowania, analityka, segmenty Dziś/Analityka z ich toolbarem) działają bez regresji — zmiana addytywna poza jednym warunkiem widoczności toolbaru w segmencie Ćwiczenia.
- Ekrany Tablicy pozostają płynne (liczniki i PR liczone z pełnej historii nie blokują UI).
- Dane PR nie opuszczają urządzenia; żadnego współdzielenia przez App Group (decyzja: niepotrzebne).

## Functional Requirements

### Katalog ruchów
- FR-001: Użytkownik może przeglądać katalog ruchów w 5 stałych kategoriach (Olimpijskie, Siła, Gimnastyka, Kondycja, Benchmarki) pogrupowanych podgrupami, z notatką standardu Rx przy benchmarkach; katalog startowy to ścięty rdzeń ~25–30 ruchów. Priorytet: musi być. Zmiana: nowa
  > Sokrates: rozważono "katalog-cmentarz" (60 pustych ruchów zagrzebie 10 trenowanych). Rozwiązanie: katalog ścięty do rdzenia na start; reszta dojdzie z użycia.
- FR-002: Katalog jest statyczną tablicą Swift w SharedModels (wzorzec ExerciseType) i ma mostek do istniejącego świata: opcjonalne pole exerciseType per ruch + wodAliases benchmarków (grunt pod auto-detekcję w skanie — iteracja 2). Priorytet: musi być. Zmiana: nowa
  > Sokrates: rozważono JSON w bundlu (spec) vs drugi mechanizm katalogowy + loader. Rozwiązanie: statyczny Swift — jeden język mechanizmów, type-safety id, szybciej przy 2-tygodniowym terminie; "dodawanie bez rekompilacji" i tak nie działa dla appki z bundla.
- FR-003: ~~Własne ruchy użytkownika~~ — PRZENIESIONE do iteracji 2. Zmiana: n/d
  > Sokrates: duplikaty z literówkami rozjadą katalog, a przy 2-tygodniowym terminie to czysty koszt. Rozwiązanie: wypada z MVP; wraca w iteracji 2.

### Wpisy wyników
- FR-004: Użytkownik może zapisać wynik ruchu z metadanymi: data (domyślnie dziś), wartość wg typu wyniku, Rx/scaled (tylko gdzie ruch to wspiera), sprzęt, kontekst (fresh/inWod/competition, domyślnie fresh), RPE, notatka; masa ciała zapisuje się automatycznie jako snapshot z HealthKit (PersonalDataClient). Priorytet: musi być. Zmiana: nowa
  > Sokrates: rozważono tarcie 8-polowego formularza. Rozwiązanie: bez zmian — metadane to sedno wartości (rekord z pasem ≠ bez pasa); domyślne wartości minimalizują tarcie.
- FR-005: Wartości wprowadzane są przez dedykowane kontrolki per typ wyniku z walidacją (mm:ss dla czasu, stepper dla powtórzeń, rundy+powtórzenia dla AMRAP; bez parsowania stringów); przycisk zapisu nieaktywny przy niepoprawnej wartości. Kontrolki przez REUŻYCIE istniejących komponentów Summary (TimePickerField, wzorce SetTable/InlineResultEditor). Priorytet: musi być. Zmiana: nowa
  > Sokrates: rozważono koszt 8 komponentów przy 2 tygodniach. Rozwiązanie użytkownika: komponenty wejściowe już istnieją w Summary — reużycie, nie pisanie od zera; kontrargument kosztowy upada.
- FR-006: Użytkownik może usunąć wpis (swipe z potwierdzeniem); PR przelicza się automatycznie. Priorytet: musi być. Zmiana: nowa
  > Sokrates: rozważono nieodwracalność twardego usunięcia (incydent utraty danych w historii projektu). Rozwiązanie: potwierdzenie wystarczy na MVP; soft-delete/undo bez dowodu potrzeby.

### Wyznaczanie PR
- FR-007: System wyznacza aktualny PR per ruch jako czystą funkcję z historii wpisów: kierunek wg typu wyniku (czas: mniej = lepiej), AMRAP leksykograficznie (rundy, powtórzenia), osobne PR-y Rx i scaled (scaled nigdy nie bije Rx), remis rozstrzyga nowsza data; bez zdenormalizowanego bestValue w bazie. Priorytet: musi być. Zmiana: nowa
  > Sokrates: rozważono cache bestValue (szybszy odczyt) vs rozjazd dwóch źródeł prawdy. Rozwiązanie: czysta funkcja (wariant A) — usunięcie wpisu samo cofa PR; przy setkach wpisów wydajność bez znaczenia.
- FR-008: CrossFit Total liczy się automatycznie z wpisów back squat + strict press + deadlift z tego samego dnia; przy braku kompletu można wpisać ręcznie. Priorytet: miły dodatek. Zmiana: nowa
  > Sokrates: rozważono kruchość reguły same-day i konkurencję z terminem. Rozwiązanie: zostaje jako miły dodatek (poza ścieżką krytyczną; realizowany, jeśli starczy czasu).

### Widoki
- FR-009: Użytkownik widzi ekran kategorii (liczniki uzupełnienia, data ostatniego PR), listę ruchów w podgrupach (aktualny PR + względna data; ruchy puste wyszarzone, ale widoczne) i szczegół ruchu (duża wartość PR, wykres postępu z osią odwróconą dla czasu — renderowany od 2+ wpisów, historia malejąco po dacie, badge Rx/Scaled, ikona sprzętu, krotność masy ciała dla ruchów kg). Priorytet: musi być. Zmiana: nowa
  > Sokrates: rozważono wykres przy 1–2 wpisach (nic nie pokazuje). Rozwiązanie: wykres zostaje (wzorce Swift Charts świeże z RouteDetails), ale renderuje się od 2 wpisów.
- FR-010: Wejście do Tablicy: w segmencie Ćwiczenia zakładki Statystyki toolbar pokazuje wyłącznie przycisk Tablicy PR (globalne crown/AI/profil ukryte w tym segmencie). Priorytet: musi być. Zmiana: zmodyfikowana (warunek widoczności w istniejącym StatsView.toolbar)
  > Sokrates: rozważono niespójność nawigacji (profil znika w jednym segmencie). Rozwiązanie: podmiana zostaje — kontekst Ćwiczeń ma być czysty; profil/AI dostępne w segmentach Dziś/Analityka.

### Zachowane
- FR-011: Segmenty Dziś i Analityka zakładki Statystyki zachowują dotychczasowy toolbar i zachowanie bez zmian; przełączanie segmentów bez migotania toolbara (jawne kryterium akceptacji). Zmiana: zachowana
  > Sokrates: warunek widoczności w StatsView może migotać przy przełączaniu segmentów. Rozwiązanie: dopisane jako kryterium akceptacji.
- FR-012: Istniejące tabele i przepływy treningowe działają bez zmian — moduł dokłada wyłącznie nowe tabele (migracja v12, append-only, zgodnie z regułą Schema.swift) i czyta profil przez istniejący PersonalDataClient. Zmiana: zachowana
  > Sokrates: nowa migracja w DEBUG kasuje bazę na urządzeniu dev (eraseDatabaseOnSchemaChange — incydent z sierpnia). Rozwiązanie: nota do planu implementacji — zaplanować moment migracji/backup danych dev.

## User Stories

### US-01: Trenujący zapisuje wynik i widzi zaktualizowany PR

- **Given** użytkownik w segmencie Ćwiczenia z widoczną Tablicą PR i katalogiem ruchów
- **When** wchodzi w Siła → Back Squat i zapisuje wpis 150 kg, kontekst fresh, z pasem (belt)
- **Then** szczegół ruchu pokazuje nowy PR 150 kg z dzisiejszą datą, ikoną sprzętu i krotnością masy ciała, a licznik kategorii Siła rośnie

#### Acceptance Criteria
- Wpis trwały między uruchomieniami aplikacji
- PR wyliczony z historii (nie zapisany osobno) — usunięcie wpisu cofa PR do poprzedniego
- Masa ciała dopisana automatycznie jako snapshot (jeśli HealthKit ją zwraca; brak zgody nie blokuje zapisu)

### US-02: Trenujący porównuje benchmark Rx i scaled

- **Given** użytkownik z wcześniejszym wpisem Fran 6:30 scaled
- **When** zapisuje nowy wynik Fran 8:10 Rx
- **Then** szczegół Fran pokazuje dwa osobne PR-y: Rx 8:10 i Scaled 6:30 — wynik scaled nie bije Rx mimo lepszego czasu

## Business Logic

System wyznacza aktualny rekord życiowy per ruch wyłącznie z historii wpisów: kierunek „lepszego" wyniku zależy od typu wyniku (czas: mniej = lepiej), wyniki Rx i scaled są osobnymi rekordami (scaled nigdy nie bije Rx), AMRAP porównuje się leksykograficznie (rundy, potem powtórzenia), a remis rozstrzyga nowsza data.

Wejścia reguły: wpisy użytkownika (wartość wg typu wyniku, flaga Rx/scaled, data). Wyjście: aktualny PR per ruch (dla benchmarków para: Rx i scaled), liczniki uzupełnienia kategorii i oznaczenie pobicia. Użytkownik spotyka regułę na szczególe ruchu (duża wartość PR), na listach (PR + względna data) i w momencie zapisu wpisu (natychmiastowe przeliczenie).

To NOWA reguła — istniejące reguły systemu (dopasowanie katalogowe ćwiczeń, Effort Points, readiness) pozostają nietknięte. Reguła pomocnicza (miły dodatek): CrossFit Total = suma back squat + strict press + deadlift z wpisów tego samego dnia.

## Non-Functional Requirements

- Ekrany Tablicy otwierają się bez zauważalnego oczekiwania mimo wyznaczania PR z pełnej historii — brak widocznego zamrożenia UI przy wejściu w kategorię/ruch.
- Tablica jest wizualnie i nawigacyjnie nieodróżnialna od reszty aplikacji (iOS 26 Liquid Glass, konwencje przejść) — mierzalne przeglądem porównawczym z sąsiednimi ekranami Statystyk.

## Constraints & Preserved Behavior

- Zero modyfikacji istniejących tabel i migracji — wyłącznie nowe tabele w migracji v12 (append-only, zgodnie z regułą Schema.swift: nigdy nie edytować zarejestrowanej migracji).
- Baza zostaje w Application Support — żadnej migracji ścieżki, żadnego App Group (decyzja: współdzielenie z widgetami/Watch niepotrzebne).
- Wszystkie istniejące przepływy treningowe i segmenty Dziś/Analityka (wraz z ich toolbarem) bez zmian; przełączanie segmentów bez migotania toolbara.
- Integracja z profilem wyłącznie do odczytu przez istniejący PersonalDataClient (masa ciała jako snapshot); żadnych nowych pól profilu.
- Mosty katalogu (exerciseType, wodAliases) w MVP uśpione — żaden istniejący mechanizm (skan, analityka) nie zmienia zachowania.
- Migracja danych: brak (nowe tabele startują puste). Uwaga operacyjna: DEBUG `eraseDatabaseOnSchemaChange` skasuje bazę dev przy v12 — zaplanować moment/backup.

## Non-Goals

1. Analiza proporcji między bojami — osobna iteracja; grunt (czysta funkcja PR, bodyWeightKg) przygotowany.
2. Ranking społecznościowy / Gym Room — poza domeną osobistej tablicy.
3. Import z zewnętrznych aplikacji — nieweryfikowalne dane wejściowe.
4. Powiadomienia „czas na retest" — wartość niepotwierdzona, koszt harmonogramu.
5. App Group / widget / Watch dla danych PR — użytkownik: niepotrzebne; dane zostają w bazie aplikacji.
6. Auto-detekcja benchmarków w skanie + auto-dopis wyników — iteracja 2 (mosty w katalogu już gotowe).
7. Własne ruchy użytkownika — iteracja 2 (ryzyko duplikatów, termin).
8. Pełny katalog ~60 ruchów — start od rdzenia ~25–30; rozszerzenie z użycia.
9. Konwersja jednostek na funty — kg/metry na sztywno w modelu; ewentualna konwersja tylko w prezentacji, poza MVP.

## Product framing (brownfield)

- Typ produktu: bez zmian — istniejąca aplikacja mobilna (iOS/watchOS); zmiana nie dodaje nowej powierzchni produktu.
- Baza użytkowników: bez zmian — właściciel + testerzy TestFlight; zmiana nie otwiera systemu na nowych użytkowników.
- Harmonogram: delivery_weeks: 2, hard_deadline: 2026-09-07, after_hours_only: true.

## Open Questions (zebrane)

1. **Estymata 1RM (Epley) z historii serii przez most exerciseType** — czy wchodzi kiedykolwiek, a jeśli tak: iteracja 2 czy później? Właściciel: użytkownik. Nieblokujące dla MVP.
2. **Dostępność (Dynamic Type XXL, VoiceOver z jednostkami)** — obecna w spec §7, nie wybrana jako zobowiązanie NFR — potwierdzić świadomą rezygnację lub przywrócić przy planie UI. Właściciel: użytkownik. Nieblokujące.

## Forward: technical-roadmap (poza PRD — dla planu implementacji)

- Iteracja 2: auto-detekcja benchmarków w skanie AI (dopasowanie wodName do wodAliases katalogu) + auto-dopis wyniku do Tablicy (PREntry z context inWod, isRx ze scaling) po wpisaniu wyniku WOD-u; własne ruchy użytkownika (custom, wypadły z MVP); rozszerzenie katalogu ponad rdzeń ~25–30 ruchów.
- Iteracja 2+: analiza proporcji między bojami (czysta funkcja currentPR jako wejście silnika proporcji; bodyWeightKg snapshot obowiązkowy już teraz).
- Etapy implementacji wg spec użytkownika: 1 model + statyczny katalog Swift, 2 logika PR (testy wszystkich typów), 3 reducery (TestStore na głównym przepływie), 4 UI (reużycie komponentów wejściowych Summary: TimePickerField itd.); warstwa techniczna: SQLiteData v12 (uwaga: DEBUG eraseDatabaseOnSchemaChange kasuje bazę dev — zaplanować moment/backup), klient PR w stylu istniejących klientów, nawigacja @Presents.
- Otwarte z wariantu 1: estymata 1RM (Epley) z historii serii przez mostek exerciseType — użytkownik niezdecydowany (Open Questions).
