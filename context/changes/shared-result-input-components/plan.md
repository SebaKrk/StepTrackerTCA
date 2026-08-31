# Wydzielenie komponentów UI Summary do warstwy UI/ — plan implementacji

## Przegląd

F-01 z roadmapy (`pr-board-mvp`): przenosimy komponenty UI z prywatnego folderu feature'a Summary (`FeaturesNew/WorkoutTab/Session/Child/Summary/Components/`) do warstwy współdzielonej app targetu (`WorkoutMirrorLive/UI/`). Zero zmian kodu i zachowania — to ten sam moduł (target `WorkoutMirrorLive`), więc przenosiny plików nie wymagają zmian importów ani API. Odblokowuje S-02/S-03 (formularz wpisu w Tablicy PR złoży się z tych kontrolek).

Decyzja użytkownika (2026-08-31): przenosimy WSZYSTKIE pliki z `Summary/Components/` (nie tylko 4 współdzielone) — cały UI komponentowy ma mieszkać w `UI/`. Kompromisy omówione i zaakceptowane.

## Analiza bieżącego stanu

- `Summary/Components/` zawiera 15 plików komponentów (lista niżej), wszystkie `internal`, konsumowane wewnątrz Summary; wyjątki: `SummaryTheme.swift` używany też przez `UI/HeartRate/HeartRateZonesSection.swift` (inwersja: warstwa shared → feature) i `ActivityPlanScoreView.swift` (`SummaryTheme.mint`, `.environment(\.summaryPalette, .native)`).
- Kontrolki wejściowe: `TimePickerField` (mm:ss, czysty SwiftUI, zero domeny), `DNFFields` (rundy+powtórzenia, czysty SwiftUI), `SetTable` (serie siłowe, zależy tylko od `SetEntry` z SharedModels). Wszystkie closure-driven, bez `@State`, zależne od `@Environment(\.summaryPalette)` + `SummaryTheme.innerRadius`.
- `InlineResultEditor` jest store-driven (`@ViewAction(for: WODScoringFeature.self)`) — przenosimy plik bez zmian; NIE przerabiamy go na kontrolkę reużywalną.
- Projekt używa `fileSystemSynchronizedGroups` (6 wystąpień w `MyFitnessJournal.xcodeproj/project.pbxproj`) — pliki wchodzą do builda z dysku; przeniesienie w obrębie drzewa targetu nie wymaga edycji pbxproj.
- `Summary/Child/SetInput/` (4 pliki, 538 linii) to martwy kod (zero użyć w repo) — decyzja użytkownika: ZOSTAJE, tylko odnotowany.

### Kluczowe odkrycia:

- Precedens identycznego ruchu: `HRMinuteRangeChart` przeniesiony verbatim z Summary do `UI/HeartRate/` (`HeartRateZonesView+Chart.swift:47`).
- Konsumenci, którzy muszą kompilować się bez zmian: `SummaryView.swift`, `WorkoutResultsView.swift:44`, `ResultCardView.swift:76,183`, `ActivityPlanScoreView.swift:64,66,70`, `UI/HeartRate/HeartRateZonesSection.swift:74-109`.
- `SetTable`/`DNFFields`/`InlineResultEditor` mają twardo zakodowane `Color.white.opacity(...)` nieadaptujące się do palety `.native` — świadomie NIE ruszamy (dotyczy S-02 przy planie UI Tablicy).

## Pożądany stan końcowy

`Summary/Components/` nie istnieje; komponenty żyją w `UI/ResultEntry/` (4 pliki współdzielone z przyszłą Tablicą PR) i `UI/Summary/` (11 plików specyficznych dla Podsumowania). Aplikacja buduje się i wygląda identycznie (Summary, ActivityDetails → wynik planu). Weryfikacja: build + porównanie wizualne + `git diff -M` pokazujący wyłącznie przeniesienia (rename 100%, zero zmian treści).

## Czego NIE robimy

- Żadnych zmian w kodzie przenoszonych plików (ani jednej linii — czyste `git mv`).
- Nie kasujemy martwego `Child/SetInput/` (decyzja użytkownika: zostaje).
- Nie przepisujemy `InlineResultEditor` na closure-driven.
- Nie naprawiamy twardych `Color.white.opacity(...)` pod paletę `.native` (S-02).
- Nie zmieniamy nazw typów ani plików (np. `SummaryTheme` zachowuje nazwę mimo nowej lokalizacji).
- Nie dotykamy `Summary/Child/` (WODScoring, WorkoutResults, SetInput zostają).

## Podejście do implementacji

Dwa atomowe commity (konwencja repo: subtask = kompilujący się, logicznie zamknięty commit): najpierw 4 pliki odblokowujące S-02 (sedno F-01), potem pozostałe 11 (porządek „cały UI w UI/"). Przenosiny przez `git mv` (zachowuje historię i pokazuje rename w diffie). Po każdej fazie build i weryfikacja wizualna po stronie użytkownika (konwencja repo: builduje wyłącznie użytkownik).

## Faza 1: Wydzielenie kontrolek wyników → UI/ResultEntry/

### Przegląd

Przeniesienie 4 plików, które będą współdzielone z Tablicą PR (S-02/S-03) — właściwe „odblokowanie" F-01.

### Wymagane zmiany:

#### 1. Przeniesienie plików

**Pliki** (z `WorkoutMirrorLive/FeaturesNew/WorkoutTab/Session/Child/Summary/Components/` do `WorkoutMirrorLive/UI/ResultEntry/`):
- `TimePickerField.swift`
- `DNFFields.swift`
- `SetTable.swift`
- `SummaryTheme.swift`

**Cel**: kontrolki wejściowe + ich motyw dostępne z warstwy współdzielonej; przy okazji znika inwersja `UI/HeartRate → feature Summary`.

**Kontrakt**: czyste `git mv` — zero zmian treści plików; ten sam moduł, więc wszyscy dotychczasowi konsumenci kompilują się bez edycji.

### Kryteria sukcesu:

#### Weryfikacja automatyczna:

- `git diff -M --summary` pokazuje wyłącznie rename 100% dla 4 plików
- Pliki nieobecne w `Summary/Components/`, obecne w `UI/ResultEntry/`
- `grep` nazw 4 plików w `project.pbxproj` zwraca 0 trafień

#### Weryfikacja ręczna:

- Build `WorkoutMirrorLive` przechodzi (użytkownik)
- Summary i ActivityPlanScore wyglądają identycznie (użytkownik)

**Uwaga implementacyjna**: po zielonych kryteriach zatrzymaj się na ręczne potwierdzenie użytkownika (build + rzut oka) przed Fazą 2. Commit Fazy 1 wykonuje użytkownik.

---

## Faza 2: Przeniesienie pozostałych komponentów Summary → UI/Summary/

### Przegląd

Realizacja decyzji „cały UI komponentowy w `UI/`" — pozostałe pliki specyficzne dla Podsumowania.

### Wymagane zmiany:

#### 1. Przeniesienie plików

**Pliki** (z `Summary/Components/` do `WorkoutMirrorLive/UI/Summary/`):
- `InlineResultEditor.swift`
- `ResultCardView.swift`
- `ResultCardHeader.swift`
- `HeroCard.swift`
- `MetricTile.swift`
- `ScoreLine.swift`
- `StatusControl.swift`
- `NoteRow.swift`
- `CardActionButton.swift`
- `SaveWorkoutButton.swift`
- `ExerciseList.swift`

**Cel**: opróżnienie `Summary/Components/`; komponenty ekranu Podsumowania w jednym miejscu w `UI/`.

**Kontrakt**: czyste `git mv`; przed startem `ls Summary/Components/` — jeśli folder zawiera pliki spoza listy (spis z badania 2026-08-31), przenieś również je i odnotuj w Progress. Po przeniesieniu usuń pusty folder `Components/`.

### Kryteria sukcesu:

#### Weryfikacja automatyczna:

- `git diff -M --summary` pokazuje wyłącznie rename 100% dla plików fazy
- `Summary/Components/` usunięty; komplet w `UI/Summary/`
- `grep` nazw 11 plików w `project.pbxproj` zwraca 0 trafień

#### Weryfikacja ręczna:

- Build `WorkoutMirrorLive` przechodzi (użytkownik)
- Pełny ekran Podsumowania wygląda identycznie (użytkownik)

**Uwaga implementacyjna**: commit Fazy 2 wykonuje użytkownik.

---

## Strategia testowania

Zmiana bez zmian kodu — istniejące testy pakietów SPM nie są dotknięte (komponenty żyją w app targecie, poza pakietami). Weryfikacja opiera się na: (1) niezmienności treści plików (`git diff -M` = rename 100%), (2) buildzie użytkownika, (3) porównaniu wizualnym Summary i ActivityPlanScore. Nowych testów nie piszemy (konwencja repo).

## Uwagi dotyczące migracji

Brak — zero zmian w danych, schemacie i zachowaniu.

## Referencje

- Roadmapa: `context/foundation/roadmap.md` (F-01, odblokowuje S-02/S-03)
- PRD: `context/foundation/prd.md` (FR-005 + nota kosztowa „to przenosiny, nie import")
- Precedens: `WorkoutMirrorLive/UI/HeartRate/HeartRateZonesSection.swift` (ruch verbatim z Summary)

## Noticed

- `Summary/Child/SetInput/` (4 pliki, 538 linii) — martwy kod bez ani jednego użycia; funkcję przejęły `InlineResultEditor`+`SetTable`+`DNFFields`. Decyzja: zostaje; kandydat na osobny ticket porządkowy.
- Twarde `Color.white.opacity(...)` w `SetTable`/`DNFFields`/`InlineResultEditor` nie adaptują się do palety `.native` — do rozważenia przy planie UI S-02.
- Nazwa `SummaryTheme`/`summaryPalette` po przeprowadzce do warstwy współdzielonej robi się myląca (używa jej też HeartRate i ActivityPlanScore, a wkrótce Tablica PR) — ewentualna zmiana nazwy to osobna, mechaniczna zmiana.

## Postęp

> Konwencja: `- [ ]` oczekujące, `- [x]` wykonane. Dodaj ` — <commit sha>` po zakończeniu kroku. Nie zmieniaj tytułów kroków.

### Faza 1: Wydzielenie kontrolek wyników → UI/ResultEntry/

#### Automatyczne

- [x] 1.1 `git diff -M --summary` pokazuje wyłącznie rename 100% dla 4 plików
- [x] 1.2 Pliki nieobecne w `Summary/Components/`, obecne w `UI/ResultEntry/`
- [x] 1.3 `grep` nazw 4 plików w `project.pbxproj` zwraca 0 trafień

#### Ręczne

- [x] 1.4 Build `WorkoutMirrorLive` przechodzi (użytkownik)
- [x] 1.5 Summary i ActivityPlanScore wyglądają identycznie (użytkownik)

### Faza 2: Przeniesienie pozostałych komponentów Summary → UI/Summary/

#### Automatyczne

- [ ] 2.1 `git diff -M --summary` pokazuje wyłącznie rename 100% dla plików fazy
- [ ] 2.2 `Summary/Components/` usunięty; komplet w `UI/Summary/`
- [ ] 2.3 `grep` nazw 11 plików w `project.pbxproj` zwraca 0 trafień

#### Ręczne

- [ ] 2.4 Build `WorkoutMirrorLive` przechodzi (użytkownik)
- [ ] 2.5 Pełny ekran Podsumowania wygląda identycznie (użytkownik)
