# Tablica PR — usuwanie wpisu z przeliczeniem PR (S-05): plan implementacji

## Przegląd

Użytkownik usuwa wpis z historii ruchu (long-press → menu kontekstowe → potwierdzenie), a PR i liczniki wracają do poprzedniego stanu same — bo PR jest zawsze liczony z historii (`PRResolver`), a ekrany obserwują bazę (`@FetchAll`). Dodatkowo: test TestStore głównego przepływu edytora (ostatni wymóg certyfikacji „≥1 test przepływu użytkownika"). Realizowany równolegle z S-06 (ćwiczenie lekcji o pracy wieloagentowej) — w izolowanym worktree.

## Analiza stanu obecnego

- Historia wpisów: `PRMovementDetailView.historyRow` (karta w ScrollView — dlatego swipe niemożliwy: `swipeActions` działa tylko w List; decyzja użytkownika: long-press + potwierdzenie).
- Klient ma tylko `save` (`PREntryClient.swift`); wzorzec delete: `ClassParticipationClient.deleteByHKWorkoutId` (`.where{}.delete().execute(db)`).
- `@FetchAll` w trzech State'ach PRBoard — usunięcie w bazie samo odświeży hero/listę/liczniki (FR-007: „usunięcie wpisu cofa PR").
- Wzorzec potwierdzenia: `ExerciseDetailFeature` ma `@Presents var alert: AlertState<...>` z case'em potwierdzenia usunięcia (`+State.swift:57`, alert w View `:50`).
- App target NIE MA targetu testów jednostkowych — TestStore test wymaga dodania targetu w Xcode (reguła repo: zmiany project.pbxproj przez Xcode UI, nie skrypty).

## Pożądany stan końcowy

Long-press na wierszu historii → „Usuń wpis" → potwierdzenie → wpis znika, PR na hero wraca do poprzedniej wartości, licznik kategorii maleje gdy to był ostatni wpis ruchu. Test `PREntryEditorFeatureTests` (TestStore, withDependencies) zielony w Xcode (Cmd+U).

## Czego NIE robimy

- Swipe (wymaga List — świadome odstępstwo od litery FR-006, potwierdzone przez użytkownika; potwierdzenie usunięcia zostaje).
- Undo/soft-delete (PRD: twarde usunięcie z potwierdzeniem wystarcza).
- Edycji wpisu; zmian w S-06 (równoległa zmiana — nie dotykać wykresu/hero poza dodaniem menu na wierszu).
- Testów w CI dla app targetu (test biega w Xcode; CI pokrywa pakiety).

## Podejście do implementacji

Dwie fazy: (1) delete end-to-end (klient + reducer + menu/dialog), (2) test przepływu edytora (z ręcznym krokiem: user tworzy target testowy w Xcode UI). Konwencje TCA jak w S-02 (`@CasePathable` w extension, `some Reducer<State, Action>`, zero `@State`).

## Faza 1: Usuwanie wpisu end-to-end

### Wymagane zmiany:

#### 1. Klient — delete

**Plik**: `WorkoutMirrorLive/FeaturesNew/PRBoard/Client/PREntryClient.swift`

**Cel**: granica usuwania wpisu po id.

**Kontrakt**: `var delete: @Sendable (UUID) async throws -> Void`; liveValue: `database.write { try PREntryRecord.where { $0.id.eq(id) }.delete().execute(db) }` (wzorzec ClassParticipationClient); `testValue` += `unimplemented`.

#### 2. Reducer szczegółu — akcje usuwania z potwierdzeniem

**Pliki**: `PRMovementDetailFeature.swift`, `+State.swift`, `+Action.swift`

**Cel**: przepływ long-press → dialog → delete; zero ręcznego przeliczania (obserwacja bazy załatwia resztę).

**Kontrakt**: State += `@Presents var confirmationDialog: ConfirmationDialogState<Action.Dialog>?`; Action: view += `deleteEntryTapped(PREntry)`, nowy `case confirmationDialog(PresentationAction<Dialog>)` z `@CasePathable enum Dialog { case confirmDelete(UUID) }`; reducer: tap → wypełnij dialog (tytuł z wartością wpisu i datą, destructive „Usuń wpis"), confirm → `.run { try await prEntryClient.delete(id) }` z `reportIssue` na błąd; `@Dependency(\.prEntryClient)`; `.ifLet(\.$confirmationDialog, ...)`.

#### 3. Widok — menu kontekstowe i dialog

**Plik**: `PRMovementDetailView.swift`

**Cel**: odkrywalne usuwanie bez przebudowy kart.

**Kontrakt**: `historyRow` += `.contextMenu { deleteButton(entry) }` (Button role: .destructive, verbose, w private func); na content `.confirmationDialog($store.scope(...))`; teksty przez `String(localized:)`.

### Kryteria sukcesu:

#### Weryfikacja automatyczna:

- `grep -n "delete" WorkoutMirrorLive/FeaturesNew/PRBoard/Client/PREntryClient.swift` znajduje operację
- `swift test --package-path SharedModels` i `swift test --package-path AppDatabase` zielone (bez regresji)

#### Weryfikacja ręczna:

- Build przechodzi; long-press → potwierdzenie → wpis znika; PR wraca do poprzedniej wartości po usunięciu najlepszego wpisu; licznik kategorii maleje po usunięciu ostatniego wpisu ruchu (użytkownik)

---

## Faza 2: Test TestStore przepływu edytora

### Wymagane zmiany:

#### 1. Target testowy aplikacji (ręcznie, Xcode UI)

**Cel**: miejsce na testy reducerów app targetu (pierwszy raz w projekcie).

**Kontrakt**: user dodaje w Xcode: File → New → Target → Unit Testing Bundle, nazwa `WorkoutMirrorLiveTests`, host: WorkoutMirrorLive. Zero edycji pbxproj poza Xcode.

#### 2. Test przepływu

**Plik**: `WorkoutMirrorLiveTests/PREntryEditorFeatureTests.swift` (nowy)

**Cel**: wymóg certyfikacji — test przepływu użytkownika: wpisanie kg → save → zapis przez klienta → dismiss.

**Kontrakt**: swift-testing + `TestStore`; `withDependencies`: `prEntryClient.save` przechwytuje zapisany `PREntry` (LockIsolated), `personalDataClient` stub (getWeightForDate → nil), `uuid: .incrementing`, `date.now` stały (`Date(timeIntervalSince1970:)` — lessons.md), `dismiss: DismissEffect { … }` potwierdzony. Scenariusz: State(movement: back-squat, now: fixed) → `binding weightText "150"` → `view.saveTapped` → assert: zapisany entry (movementId, score .weight(150), context .fresh, bodyWeightKg nil) + dismiss wywołany. Drugi test: `weightText "0"` → `isSaveDisabled == true`.

### Kryteria sukcesu:

#### Weryfikacja automatyczna:

- `ls WorkoutMirrorLiveTests/PREntryEditorFeatureTests.swift` przechodzi

#### Weryfikacja ręczna:

- Target testowy dodany w Xcode (użytkownik)
- Testy zielone w Xcode / Cmd+U (użytkownik)

---

## Strategia testowania

Faza 2 = pierwszy test przepływu reducera w projekcie (TestStore, exhaustive). Regresje pakietów pilnowane w kryteriach automatycznych. Efekt „PR cofa się po usunięciu" ma już pokrycie w testach czystej funkcji (PRResolver) — tu weryfikowany manualnie end-to-end.

## Referencje

- `context/changes/record-entry-current-pr/` (S-02 — cały dotykany kod)
- Wzorce: `ClassParticipationClient.swift:91-98` (delete), `ExerciseDetailFeature+State.swift:57` (alert potwierdzenia)

## Postęp

> Konwencja: `- [ ]` oczekujące, `- [x]` wykonane. Dodaj ` — <commit sha>` po zakończeniu kroku. Nie zmieniaj tytułów kroków.

### Faza 1: Usuwanie wpisu end-to-end

#### Automatyczne

- [x] 1.1 `grep -n "delete" WorkoutMirrorLive/FeaturesNew/PRBoard/Client/PREntryClient.swift` znajduje operację — 6b8310e
- [x] 1.2 `swift test --package-path SharedModels` i `swift test --package-path AppDatabase` zielone (bez regresji) — 6b8310e

#### Ręczne

- [x] 1.3 Build przechodzi; long-press → potwierdzenie → wpis znika; PR wraca do poprzedniej wartości po usunięciu najlepszego wpisu; licznik kategorii maleje po usunięciu ostatniego wpisu ruchu (użytkownik)

### Faza 2: Test TestStore przepływu edytora

#### Automatyczne

- [x] 2.1 `ls WorkoutMirrorLiveTests/PREntryEditorFeatureTests.swift` przechodzi — 6b8310e

#### Ręczne

- [x] 2.2 Target testowy dodany w Xcode (użytkownik)
- [x] 2.3 Testy zielone w Xcode / Cmd+U (użytkownik)
