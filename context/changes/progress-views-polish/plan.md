# Tablica PR — wykres postępu i dopełnienie widoków (S-06): plan implementacji

## Przegląd

Domknięcie FR-009 na szczególe ruchu: wykres postępu renderowany od 2+ wpisów (oś odwrócona dla wyników czasowych — „mniej = lepiej" rośnie w górę) oraz krotność masy ciała przy PR ciężarowym (np. „×1.88 BW"). Historia malejąco, ikony sprzętu i daty względne na kategoriach już istnieją (S-02). Dostępność: świadoma rezygnacja z dedykowanych zobowiązań w MVP (decyzja użytkownika 2026-09-01 — zamyka otwarte pytanie roadmapy). Realizowany równolegle z S-05.

## Analiza stanu obecnego

- Szczegół ruchu (`PRMovementDetailView`) ma: hero „Current PR", kartę Rx, kartę History; State ma `entries` (malejąco) i `summary` (PRResolver) — dane pod wykres i krotność są na miejscu.
- Wzorce Swift Charts w repo: `ExerciseDetailView+Chart.swift`, `ExerciseAnalyticsView+Chart.swift`, `HRMinuteRangeChart` (`UI/HeartRate/`) — `import Charts`, LineMark/AreaMark, formatowanie osi.
- `PREntry.bodyWeightKg` — snapshot zapisywany od S-02 (nil gdy brak zgody HK).
- Guardrail PRD: wykres liczony z historii nie blokuje UI (dane per ruch = dziesiątki punktów — bez ryzyka).

## Pożądany stan końcowy

Ruch z ≥2 wpisami pokazuje kartę „Progress" (linia wartość-po-dacie; dla time oś odwrócona); ruch z <2 wpisami — bez karty (FR-009: „renderowany od 2+ wpisów"). Hero PR ciężarowego z zapisaną masą ciała pokazuje dopisek krotności („×N.NN BW"). Zero zmian w innych ekranach.

## Czego NIE robimy

- Zobowiązań dostępności (Dynamic Type XXL, VoiceOver z jednostkami) — świadoma rezygnacja w MVP; systemowych zachowań nie psujemy.
- Zmian w S-05 (równoległa zmiana — nie dotykać klienta, historii-menu ani dialogów).
- Wykresu na liście ruchów/kategorii; porównań Rx/scaled na wykresie (S-04); eksportu.
- Zmiany skinu (temat „ciemny motyw Summary" wraca osobno — decyzja użytkownika z 2026-08-31).

## Podejście do implementacji

Dwie fazy = dwa commity: (1) karta wykresu, (2) krotność masy ciała. Wszystko w obrębie `PRMovementDetail` (State computed + widok), stylistyka kart jak dotychczas (`styledGroupBox`).

## Faza 1: Karta wykresu postępu

### Wymagane zmiany:

#### 1. Punkty wykresu w State

**Plik**: `PRMovementDetailFeature+State.swift`

**Cel**: dane wykresu jako computed (bez nowego stanu) — data → wartość skalarna per typ wyniku.

**Kontrakt**: `var chartPoints: [(date: Date, value: Double)]` — z `entries` (rosnąco po dacie dla osi X); skalar: weight = kg, time = sekundy, reps = liczba, amrap = `rounds + extraReps/100`; `var isTimeScored: Bool` (steruje odwróceniem osi); `var showsChart: Bool { entries.count >= 2 }`.

#### 2. Karta Progress w widoku

**Plik**: `PRMovementDetailView.swift`

**Cel**: FR-009 — wykres od 2+ wpisów, oś odwrócona dla czasu.

**Kontrakt**: nowa karta `progressCard` (GroupBox label „Progress" + Divider, `.styledGroupBox()`, wysokość ~180) między hero a Historią, renderowana gdy `store.showsChart`; `import Charts`; `LineMark` + `PointMark` (x: data, y: wartość), akcent `store.movement.category.color`; dla `isTimeScored` oś Y odwrócona (domena od max do min) i etykiety osi w mm:ss (`PRScoreFormatter`-owa logika czasu); dla weight etykieta „kg". Fasada: struktura u góry, style na dole.

### Kryteria sukcesu:

#### Weryfikacja automatyczna:

- `grep -n "import Charts" WorkoutMirrorLive/FeaturesNew/PRBoard/Child/PRMovementDetail/PRMovementDetailView.swift` znajduje import
- `grep -r "@State" WorkoutMirrorLive/FeaturesNew/PRBoard/` zwraca 0 trafień

#### Weryfikacja ręczna:

- Ruch z 1 wpisem: brak karty Progress; po dodaniu 2. wpisu karta się pojawia (użytkownik)
- Wykres rośnie w górę dla cięższych wpisów (weight); preview/manualnie sprawdzona oś dla czasu — lepszy (krótszy) czas wyżej (użytkownik)

---

## Faza 2: Krotność masy ciała na hero

### Wymagane zmiany:

#### 1. Krotność w State i hero

**Pliki**: `PRMovementDetailFeature+State.swift`, `PRMovementDetailView.swift`

**Cel**: US-01 — „krotność masy ciała" przy PR ciężarowym.

**Kontrakt**: State: `var bodyWeightMultiple: Double?` — tylko gdy `summary.best` ma score `.weight` i `bodyWeightKg` wpisu > 0; wartość = kg / bodyWeightKg. Widok: w `currentPRCard` pod wartością caption „×1.88 BW" (format 2 miejsca, `.secondary`); brak — nic (bez placeholdera).

### Kryteria sukcesu:

#### Weryfikacja automatyczna:

- `grep -n "bodyWeightMultiple" WorkoutMirrorLive/FeaturesNew/PRBoard/Child/PRMovementDetail/Feature/PRMovementDetailFeature+State.swift` znajduje property

#### Weryfikacja ręczna:

- Build przechodzi; wpis z zapisaną masą ciała pokazuje „×N.NN BW" na hero; wpis bez snapshotu — bez dopisku (użytkownik)

---

## Strategia testowania

Logika skalara/krotności trywialna i pokryta wizualnie; bez nowych testów (reguła repo). Regresje pakietów pilnowane w S-05 (równoległym) — tu kryteria grep + manual.

## Referencje

- Wzorce Charts: `ExerciseDetailView+Chart.swift`, `UI/HeartRate/HeartRateZonesSection.swift:155`
- Roadmapa S-06 + PRD FR-009, US-01

## Postęp

> Konwencja: `- [ ]` oczekujące, `- [x]` wykonane. Dodaj ` — <commit sha>` po zakończeniu kroku. Nie zmieniaj tytułów kroków.

### Faza 1: Karta wykresu postępu

#### Automatyczne

- [ ] 1.1 `grep -n "import Charts" WorkoutMirrorLive/FeaturesNew/PRBoard/Child/PRMovementDetail/PRMovementDetailView.swift` znajduje import
- [ ] 1.2 `grep -r "@State" WorkoutMirrorLive/FeaturesNew/PRBoard/` zwraca 0 trafień

#### Ręczne

- [ ] 1.3 Ruch z 1 wpisem: brak karty Progress; po dodaniu 2. wpisu karta się pojawia (użytkownik)
- [ ] 1.4 Wykres rośnie w górę dla cięższych wpisów (weight); preview/manualnie sprawdzona oś dla czasu — lepszy (krótszy) czas wyżej (użytkownik)

### Faza 2: Krotność masy ciała na hero

#### Automatyczne

- [ ] 2.1 `grep -n "bodyWeightMultiple" WorkoutMirrorLive/FeaturesNew/PRBoard/Child/PRMovementDetail/Feature/PRMovementDetailFeature+State.swift` znajduje property

#### Ręczne

- [ ] 2.2 Build przechodzi; wpis z zapisaną masą ciała pokazuje „×N.NN BW" na hero; wpis bez snapshotu — bez dopisku (użytkownik)
