---
project: "MyFitnessJournal — Tablica PR (PR Board)"
version: 1
status: draft
created: 2026-08-27
context_type: brownfield
product_type: mobile
target_scale:
  users: small
  qps: low
  data_volume: small
timeline_budget:
  delivery_weeks: 2
  hard_deadline: 2026-09-07
  after_hours_only: true
---

# PRD — Tablica PR (PR Board)

## Current System Overview

- Cel systemu: aplikacja iOS/watchOS do prowadzenia i analizy treningów siłowych/CrossFit (MyFitnessJournal).
- Architektura: aplikacja natywna z lokalnymi pakietami SPM (SharedModels, HealthHub, AppDatabase, PeerMirror, Commons); wzorzec TCA (reducery) + "głupie" widoki SwiftUI; nawigacja przez @Presents/sheet/fullScreenCover (bez StackState).
- Stos: Swift 6, SwiftUI, The Composable Architecture, SQLiteData (migracje v1–v11, append-only, baza w Application Support), HealthKit, WatchConnectivity, CoreBluetooth, iOS 26+ (Liquid Glass).
- Baza użytkowników: właściciel aplikacji + testerzy TestFlight; trening siłowy/CrossFit.
- Kluczowa funkcjonalność dziś: sesje treningowe live (dwie ścieżki: Watch-primary / iPhone-standalone), plany ze skanem AI (ekstrakcja ćwiczeń + wodName), logi serii (ExerciseLogRecord: actualWeight kg, setsData z typowanym reps, scaling rx/scaled, isPR), podsumowania, analityka ćwiczeń (segment Ćwiczenia w zakładce Statystyki), katalog ExerciseType v6 z aliasami i mechanizmem re-match.
- Miejsce zabudowy zmiany: zakładka Statystyki ma 3 segmenty (Dziś / Analityka / Ćwiczenia); toolbar (crown, AI, profil) zadeklarowany raz dla całej zakładki, obowiązuje we wszystkich segmentach.

## Problem Statement & Motivation

Ból: trenujący zna swoje rekordy życiowe (1RM, czasy benchmarków, max powtórzeń) z notesu albo z głowy — na sali potrzebuje ich natychmiast do doboru obciążeń, oceny progresu i porównania wyników WOD-ów.

Luka między stanem obecnym a pożądanym: system rejestruje treningi i logi serii, ale nie ma miejsca, gdzie rekordy życiowe są zebrane, porównywalne w czasie i opisane metadanymi (Rx/scaled, sprzęt, kontekst) — bez tego postęp po roku jest nieweryfikowalny.

Czemu teraz: warstwa po-treningowa (podsumowania, analityka) dojrzała; profil zawodnika (biometria, RHR, HRV, gotowość) istnieje — Tablica PR jest naturalnym rozszerzeniem statystyk i nie duplikuje profilu.

Obecne obejście i jego koszt: notes papierowy / pamięć — brak dat, brak rozróżnienia Rx/scaled i sprzętu, zero powiązania z faktyczną historią treningów.

## User & Persona

Główna persona: osoba trenująca siłowo/CrossFit z zapisaną historią treningów w MyFitnessJournal — obejmuje właściciela aplikacji i testerów TestFlight. Moment: na sali przy doborze obciążenia i po treningu przy zapisie/ocenie wyniku; przy benchmarkach — porównanie z poprzednim podejściem (Rx vs scaled).

Zmiana dla istniejących użytkowników: addytywna — nowy ekran za nowym przyciskiem w segmencie Ćwiczenia. Jedyna widoczna modyfikacja istniejącego UI: w segmencie Ćwiczenia globalne przyciski toolbara (crown/AI/profil) ustępują miejsca przyciskowi Tablicy PR. Zmiana nie otwiera systemu na nowych użytkowników.

## Success Criteria

### Primary
- Użytkownik przechodzi pełny przepływ: kategoria → ruch → wpis z metadanymi → zaktualizowany PR widoczny na szczególe ruchu i w licznikach kategorii.
- Wyznaczanie PR jest poprawne dla wszystkich typów wyniku (w tym kierunek "mniej = lepiej" dla czasu, leksykograficzne AMRAP, rozdział Rx/scaled, remis → nowsza data) — potwierdzone testami czystej funkcji.

### Secondary
- Notes zostaje w szafce: na sali użytkownik sięga po aplikację zamiast po notes/pamięć (obserwowalny sygnał, że moduł zastąpił obejście).

### Guardrails
- Istniejące przepływy (sesje live, plany, podsumowania, analityka, segmenty Dziś/Analityka z ich toolbarem) działają bez regresji — zmiana addytywna poza jednym warunkiem widoczności toolbara w segmencie Ćwiczenia; przełączanie segmentów bez migotania toolbara.
- Ekrany Tablicy pozostają płynne (liczniki i PR liczone z pełnej historii nie blokują UI).
- Tablica jest wizualnie i nawigacyjnie nieodróżnialna od reszty aplikacji — mierzalne przeglądem porównawczym z sąsiednimi ekranami Statystyk.
- Dane PR nie opuszczają urządzenia; żadnego współdzielenia z rozszerzeniami (decyzja: niepotrzebne).

## User Stories

### US-01: Trenujący zapisuje wynik i widzi zaktualizowany PR

- **Given** użytkownik w segmencie Ćwiczenia z widoczną Tablicą PR i katalogiem ruchów
- **When** wchodzi w Siła → Back Squat i zapisuje wpis 150 kg, kontekst fresh, ze sprzętem (pas)
- **Then** szczegół ruchu pokazuje nowy PR 150 kg z dzisiejszą datą, ikoną sprzętu i krotnością masy ciała, a licznik kategorii Siła rośnie

Przed zmianą: rekordy nie istnieją w systemie — użytkownik trzyma je w notesie/pamięci.

#### Acceptance Criteria
- Wpis trwały między uruchomieniami aplikacji
- PR wyliczony z historii (nie zapisany osobno) — usunięcie wpisu cofa PR do poprzedniego
- Masa ciała dopisana automatycznie jako snapshot (jeśli źródło zdrowotne ją zwraca; brak zgody nie blokuje zapisu)

### US-02: Trenujący porównuje benchmark Rx i scaled

- **Given** użytkownik z wcześniejszym wpisem Fran 6:30 scaled
- **When** zapisuje nowy wynik Fran 8:10 Rx
- **Then** szczegół Fran pokazuje dwa osobne PR-y: Rx 8:10 i Scaled 6:30 — wynik scaled nie bije Rx mimo lepszego czasu

Przed zmianą: wyniki benchmarków nie mają w systemie żadnej reprezentacji.

## Scope of Change

### Katalog ruchów
- [new] FR-001: Użytkownik może przeglądać katalog ruchów w 5 stałych kategoriach (Olimpijskie, Siła, Gimnastyka, Kondycja, Benchmarki) pogrupowanych podgrupami, z notatką standardu Rx przy benchmarkach; katalog startowy to ścięty rdzeń ~25–30 ruchów. Priorytet: musi być.
  > Sokrates: rozważono "katalog-cmentarz" (60 pustych ruchów zagrzebie 10 trenowanych). Rozwiązanie: katalog ścięty do rdzenia na start; reszta dojdzie z użycia.
- [new] FR-002: Katalog jest statycznymi danymi wkompilowanymi w aplikację (wzorzec istniejącego katalogu ćwiczeń) i ma mostek do istniejącego świata: opcjonalne odwzorowanie na typ ćwiczenia z istniejącego katalogu + aliasy nazw benchmarków (grunt pod auto-detekcję w skanie — iteracja 2). Priorytet: musi być.
  > Sokrates: rozważono katalog jako plik danych w bundlu (spec) vs drugi mechanizm katalogowy + loader. Rozwiązanie: statyczne dane w kodzie — jeden język mechanizmów, bezpieczeństwo typów identyfikatorów, szybciej przy 2-tygodniowym terminie.

### Wpisy wyników
- [new] FR-004: Użytkownik może zapisać wynik ruchu z metadanymi: data (domyślnie dziś), wartość wg typu wyniku, Rx/scaled (tylko gdzie ruch to wspiera), sprzęt, kontekst (fresh/inWod/competition, domyślnie fresh), RPE, notatka; masa ciała zapisuje się automatycznie jako snapshot z istniejącego źródła danych zdrowotnych. Priorytet: musi być.
  > Sokrates: rozważono tarcie 8-polowego formularza. Rozwiązanie: bez zmian — metadane to sedno wartości (rekord z pasem ≠ bez pasa); domyślne wartości minimalizują tarcie.
- [new] FR-005: Wartości wprowadzane są przez dedykowane kontrolki per typ wyniku z walidacją (mm:ss dla czasu, stepper dla powtórzeń, rundy+powtórzenia dla AMRAP; bez parsowania tekstu); przycisk zapisu nieaktywny przy niepoprawnej wartości. Kontrolki przez reużycie istniejących komponentów wejściowych ekranu podsumowania. Priorytet: musi być.
  > Sokrates: rozważono koszt 8 komponentów przy 2 tygodniach. Rozwiązanie użytkownika: komponenty wejściowe już istnieją w podsumowaniu — reużycie, nie pisanie od zera; kontrargument kosztowy upada.
  > Nota kosztowa: komponenty (TimePickerField, InlineResultEditor, SetInput) są dziś feature-scoped wewnątrz Summary — reużycie z zakładki Statystyki oznacza wyciągnięcie ich do warstwy współdzielonej, czyli refaktor dotykający świeżo przebudowanego ekranu podsumowania. To przenosiny, nie import — ująć jako osobną fazę w planie implementacji.
- [new] FR-006: Użytkownik może usunąć wpis (swipe z potwierdzeniem); PR przelicza się automatycznie. Priorytet: musi być.
  > Sokrates: rozważono nieodwracalność twardego usunięcia (incydent utraty danych w historii projektu). Rozwiązanie: potwierdzenie wystarczy na MVP; soft-delete/undo bez dowodu potrzeby.

### Wyznaczanie PR
- [new] FR-007: System wyznacza aktualny PR per ruch jako czystą funkcję z historii wpisów: kierunek wg typu wyniku (czas: mniej = lepiej), AMRAP leksykograficznie (rundy, powtórzenia), osobne PR-y Rx i scaled (scaled nigdy nie bije Rx), remis rozstrzyga nowsza data; bez zdenormalizowanej wartości najlepszego wyniku w bazie. Priorytet: musi być.
  > Sokrates: rozważono zapisaną wartość najlepszego wyniku (szybszy odczyt) vs rozjazd dwóch źródeł prawdy. Rozwiązanie: czysta funkcja — usunięcie wpisu samo cofa PR; przy setkach wpisów wydajność bez znaczenia.
- [new] FR-008: CrossFit Total liczy się automatycznie z wpisów back squat + strict press + deadlift z tego samego dnia; przy braku kompletu można wpisać ręcznie. Priorytet: miły dodatek.
  > Sokrates: rozważono kruchość reguły same-day i konkurencję z terminem. Rozwiązanie: zostaje jako miły dodatek (poza ścieżką krytyczną; realizowany, jeśli starczy czasu).

### Widoki
- [new] FR-009: Użytkownik widzi ekran kategorii (liczniki uzupełnienia, data ostatniego PR), listę ruchów w podgrupach (aktualny PR + względna data; ruchy puste wyszarzone, ale widoczne) i szczegół ruchu (duża wartość PR, wykres postępu z osią odwróconą dla czasu — renderowany od 2+ wpisów, historia malejąco po dacie, badge Rx/Scaled, ikona sprzętu, krotność masy ciała dla ruchów ciężarowych). Priorytet: musi być.
  > Sokrates: rozważono wykres przy 1–2 wpisach (nic nie pokazuje). Rozwiązanie: wykres zostaje, ale renderuje się od 2 wpisów.
- [modified] FR-010: Wejście do Tablicy: w segmencie Ćwiczenia zakładki Statystyki toolbar pokazuje wyłącznie przycisk Tablicy PR (globalne crown/AI/profil ukryte w tym segmencie) — modyfikacja warunku widoczności w istniejącym toolbarze zakładki Statystyki. Priorytet: musi być.
  > Sokrates: rozważono niespójność nawigacji (profil znika w jednym segmencie). Rozwiązanie: podmiana zostaje — kontekst Ćwiczeń ma być czysty; profil/AI dostępne w segmentach Dziś/Analityka.

### Zachowane
- [preserved] FR-011: Segmenty Dziś i Analityka zakładki Statystyki zachowują dotychczasowy toolbar i zachowanie bez zmian; przełączanie segmentów bez migotania toolbara (jawne kryterium akceptacji).
- [preserved] FR-012: Istniejące tabele i przepływy treningowe działają bez zmian — moduł dokłada wyłącznie nowe tabele (kolejna migracja, append-only, zgodnie z regułą istniejącego mechanizmu migracji) i czyta profil przez istniejący klient danych osobowych.
  > Sokrates: nowa migracja w konfiguracji deweloperskiej kasuje bazę na urządzeniu dev (incydent z sierpnia). Rozwiązanie: nota do planu implementacji — zaplanować moment migracji/backup danych dev.

Uwaga: dawne FR-003 (własne ruchy użytkownika) przeniesione do iteracji 2 w rundzie Sokratesa — patrz Non-Goals #7.

## Constraints & Compatibility

- Zero modyfikacji istniejących tabel i zarejestrowanych migracji — wyłącznie nowe tabele w kolejnej migracji (append-only; reguła istniejącego mechanizmu: nigdy nie edytować zarejestrowanej migracji).
- Nowe tabele projektować zgodnie z istniejącą furtką CloudKitSyncable (SyncEngine dziś niepodpięty): rekordy życiowe to ręcznie wpisywane dane bez ścieżki odzysku — zgodność schematu teraz jest darmowa, dołożenie jej później wymaga kolejnej migracji.
- Baza pozostaje w dotychczasowej lokalizacji — żadnej migracji ścieżki, żadnego współdzielenia z rozszerzeniami (widget/Watch — decyzja: niepotrzebne).
- Wszystkie istniejące przepływy treningowe i segmenty Dziś/Analityka (wraz z ich toolbarem) bez zmian; przełączanie segmentów bez migotania toolbara.
- Integracja z profilem wyłącznie do odczytu przez istniejący klient danych osobowych (masa ciała jako snapshot w momencie zapisu); żadnych nowych pól profilu.
- Mosty katalogu (odwzorowanie na typ ćwiczenia, aliasy benchmarków) w MVP uśpione — żaden istniejący mechanizm (skan AI, analityka) nie zmienia zachowania. Mostek żyje w całości po stronie nowego katalogu (mapuje NA istniejące typy); zero nowych case'ów i aliasów w ExerciseType v6 — każde takie rozszerzenie wymusza bump catalogVersion, golden testy i re-match historii, co wykracza poza zakres.
- Migracja danych: brak (nowe tabele startują puste); brak planu wycofania poza standardowym przywróceniem poprzedniej wersji aplikacji (nowe tabele są ignorowane przez starszy kod).
- Uwaga operacyjna: konfiguracja deweloperska czyści bazę przy zmianie schematu — zaplanować moment migracji/backup danych na urządzeniu dev.

## Business Logic Changes

NOWA reguła (istniejące reguły systemu — dopasowanie katalogowe ćwiczeń, punkty wysiłku, gotowość — pozostają nietknięte):

System wyznacza aktualny rekord życiowy per ruch wyłącznie z historii wpisów: kierunek "lepszego" wyniku zależy od typu wyniku (czas: mniej = lepiej), wyniki Rx i scaled są osobnymi rekordami (scaled nigdy nie bije Rx), AMRAP porównuje się leksykograficznie (rundy, potem powtórzenia), a remis rozstrzyga nowsza data.

Wejścia reguły: wpisy użytkownika (wartość wg typu wyniku, flaga Rx/scaled, data). Wyjście: aktualny PR per ruch (dla benchmarków para: Rx i scaled), liczniki uzupełnienia kategorii i oznaczenie pobicia. Użytkownik spotyka regułę na szczególe ruchu (duża wartość PR), na listach (PR + względna data) i w momencie zapisu wpisu (natychmiastowe przeliczenie).

Reguła pomocnicza (miły dodatek): CrossFit Total = suma back squat + strict press + deadlift z wpisów tego samego dnia.

## Access Control Changes

No access control changes — current model preserved.

Obecny model: aplikacja lokalna, bez logowania i ról — profil użytkownika na urządzeniu, dane lokalne za zgodami systemowymi. Nowy ekran dziedziczy model dostępu aplikacji.

## Non-Goals

1. Analiza proporcji między bojami — osobna iteracja; grunt (czysta funkcja PR, snapshot masy ciała) przygotowany.
2. Ranking społecznościowy / Gym Room — poza domeną osobistej tablicy.
3. Import z zewnętrznych aplikacji — nieweryfikowalne dane wejściowe.
4. Powiadomienia "czas na retest" — wartość niepotwierdzona, koszt harmonogramu.
5. Współdzielenie danych PR z widgetami/Watch — użytkownik: niepotrzebne; dane zostają w bazie aplikacji.
6. Auto-detekcja benchmarków w skanie + auto-dopis wyników — iteracja 2 (mosty w katalogu już gotowe).
7. Własne ruchy użytkownika — iteracja 2 (ryzyko duplikatów, termin).
8. Pełny katalog ~60 ruchów — start od rdzenia ~25–30; rozszerzenie z użycia.
9. Konwersja jednostek na funty — kilogramy/metry na sztywno w modelu; ewentualna konwersja tylko w prezentacji, poza MVP.
10. Wynik cappowany / DNF w benchmarkach (nieukończenie w time capie) — typy wyników MVP nie mają wariantu „cap + wykonane powtórzenia". Obejście na MVP: zapis jako scaled z notatką o capie. Świadoma luka — wariant wyniku do rozważenia w iteracji 2 (time cap istnieje już w modelu planów).

## Open Questions

1. **Estymata 1RM (formuła Epleya) z historii serii przez most do katalogu ćwiczeń** — czy wchodzi kiedykolwiek, a jeśli tak: iteracja 2 czy później? Właściciel: użytkownik. Nieblokujące dla MVP.
2. **Dostępność (Dynamic Type XXL, VoiceOver czytający wartości z jednostkami)** — obecna w pierwotnej specyfikacji, nie wybrana jako zobowiązanie NFR — potwierdzić świadomą rezygnację lub przywrócić przy planie UI. Właściciel: użytkownik. Nieblokujące.
3. **Dwa pojęcia „PR" w segmencie Ćwiczenia** — analityka ćwiczeń pokazuje już oznaczenie `isPR` z logów serii, a Tablica PR wyznacza rekordy z ręcznych wpisów; wartości mogą się rozjeżdżać (np. 155 kg z sesji vs 150 kg w Tablicy) w obrębie jednego segmentu. Do rozstrzygnięcia przy planie UI: rozróżnienie w copy („PR sesji" vs „rekord życiowy") lub jednostronny mostek w iteracji 2. Właściciel: użytkownik. Nieblokujące dla MVP, blokujące dla copy ekranów.
