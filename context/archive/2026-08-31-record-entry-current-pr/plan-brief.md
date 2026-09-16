# Tablica PR — zapis wpisu i aktualny PR (S-02) — krótki plan

> Pełny plan: `context/changes/record-entry-current-pr/plan.md`
> Badania: `context/changes/record-entry-current-pr/research.md`

## Co i dlaczego

Gwiazda przewodnia roadmapy: użytkownik zapisuje wynik ciężarowy z metadanymi i natychmiast widzi zaktualizowany PR na szczególe ruchu, w wierszu listy i w liczniku kategorii. To serce wartości Tablicy PR i domknięcie brakujących wymogów certyfikacji (logika biznesowa + testy).

## Punkt wyjścia

S-01 dał wejście, katalog 29 ruchów i puste ekrany („0/N", „—", „No entries yet"). Nie ma tabeli wpisów, klienta, formularza ani funkcji PR; RPE/sprzęt/picker Rx-scaled nie istnieją nigdzie w repo. Wzorce bazy (migracje v1–v11, rekordy, kliency) są żelazne i skopiowalne; sqlite-data 1.6.x wystarcza (changelog do 1.11.2 bez breaking changes — sprawdzone).

## Pożądany stan końcowy

Pełny przepływ US-01 działa i przeżywa restart aplikacji; `swift test` zielony w DWÓCH pakietach (SharedModels: testy funkcji PR; AppDatabase: test migratora v1→v12) i oba jadą w CI.

## Kluczowe podjęte decyzje

| Decyzja | Wybór | Dlaczego | Źródło |
| --- | --- | --- | --- |
| Zakres czystej funkcji | Kompletna (wszystkie typy + Rx/scaled) z testami; UI tylko weight | Testy raz; S-03/S-04 stają się czystym UI | Plan (user) |
| Gdzie funkcja i typy | SharedModels | Jedyny pakiet z testami w CI — testy wchodzą bez zmian workflow | Badania |
| Sprzęt | Enum multiselect z ikonami SF (belt, kneeSleeves, wristWraps, straps, weightVest, chalk) | US-01 wymaga ikony; dane porównywalne | Plan (user) |
| RPE | 6.0–10.0 co 0.5, picker menu, opcjonalne | Konwencja siłowa; 9 wartości = czytelny picker | Plan (user) |
| Odświeżanie ekranów | `@FetchAll` w State | Liczniki/PR aktualizują się same; S-05 dostanie odświeżanie za darmo; precedens PersonalActivity | Plan (user) |
| Test migratora | TAK — nowy testTarget AppDatabase + wpis w CI matrix | lessons.md: „przy pierwszej okazji"; v12 = pierwsza okazja | Plan (user) |
| Duplikaty dzień+ruch | Dozwolone | Historia to historia; remis rozstrzyga data→createdAt | Plan (user) |
| Data wpisu | ≤ dziś (DatePicker ograniczony) | „PR z jutra" nie istnieje | Plan (user) |
| Kto persystuje | Formularz sam (klient w dziecku) → dismiss | @FetchAll uwalnia od delegatów odświeżania | Plan |
| Wersja sqlite-data | Zostaje 1.6.x | 1.6→1.11.2 bez breaking changes; upgrade = osobny ticket | Badania |

## Zakres

**W zakresie:** typy domenowe + `PRResolver` + testy (SharedModels); `PREntryRecord` + migracja `v12_prEntries` + testTarget z testem migratora + CI matrix (AppDatabase); `PREntryClient` + formularz `PREntryEditor` (kg, data, Rx/scaled, sprzęt, RPE, notatka, snapshot masy ciała); ożywienie 3 ekranów PRBoard przez `@FetchAll`.

**Poza zakresem:** UI dla time/reps/amrap (S-03), badge Rx/Scaled (S-04), usuwanie (S-05), wykres/krotność masy (S-06), edycja wpisu, mosty katalogu, upgrade sqlite-data.

## Architektura / Podejście

Od środka na zewnątrz: czysta domena (SharedModels, testowalna w CI) → persystencja (AppDatabase, append-only v12, bez denormalizacji — PR zawsze liczony funkcją) → klient+formularz (TCA, kontrolowane zależności, dziecko persystuje i dismissuje) → prezentacja (`@FetchAll` obserwuje bazę, `PRResolver` liczy w computed State).

## Fazy w skrócie

| Faza | Co dostarcza | Kluczowe ryzyko |
| --- | --- | --- |
| 1. Domena + testy | PREntry/PRResolver + pierwsza suita testów domenowych | poprawność reguł porównań (testy łapią) |
| 2. Baza + test migratora | tabela v12, rekord, testTarget, CI×2 | DEBUG erase na urządzeniu dev (kryterium ręczne 2.4) |
| 3. Klient + formularz | sheet „dodaj wynik" z walidacją i snapshotem masy | 3 kontrolki bez precedensu (sprzęt/RPE/Rx-scaled) |
| 4. Ożywienie ekranów | liczniki, PR w wierszach, szczegół z historią | wydajność agregacji (SQL filtruje; setki wpisów = OK) |

**Wymagania wstępne:** S-01 + F-01 done (✓); gałąź `dev/10xDev/lesson2.5`.
**Szacowany nakład:** ~2 sesje, 4 commity + epilog (commituje użytkownik).

## Otwarte ryzyka i założenia

- Pierwszy build fazy 2 na fizycznym urządzeniu dev kasuje lokalną bazę (DEBUG erase) — wymaga świadomej decyzji/backupu (lessons.md, incydent 03.08).
- `@FetchAll` z zapytaniem per-ruch inicjalizowanym w `init` — wzorzec o krok dalej niż precedens (statyczne query); w razie problemów fallback: filtr w computed na `@FetchAll(all)`.

## Kryteria sukcesu (podsumowanie)

- Użytkownik przechodzi US-01 end-to-end, wpis przeżywa restart; lżejszy wpis nie zmienia PR, cięższy zmienia.
- Testy czystej funkcji pokrywają wszystkie typy wyników, remisy i rozdział Rx/scaled; test migratora zielony; oba pakiety w CI.
- Zero zdenormalizowanego „najlepszego wyniku" w bazie — usunięcie wpisu (S-05) cofnie PR samo z siebie.
