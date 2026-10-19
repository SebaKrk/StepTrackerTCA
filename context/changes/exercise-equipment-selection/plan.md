# Exercise equipment selection — plan implementacji

## Cel

Użytkownik ma widzieć sprzęt rozpoznany z nazwy ćwiczenia i móc go poprawić w planie przed treningiem. Ręczna korekta ma przetrwać zapis planu, ponowne dopasowanie katalogu, rozpoczęcie treningu i zapis wyniku. Nazwa ruchu pozostaje osobnym pojęciem od sprzętu.

Przykłady:

- `Snatch` → ruch `snatch`, domyślnie sztanga.
- `Dumbbell Snatch` → ruch `dumbbellSnatch` w obecnym katalogu; sprzęt hantle.
- jeśli matcher wybierze ruch `snatch` i wykryje hantle, interfejs pokazuje ruch `Snatch` oraz sprzęt `Hantle`, a nazwa prezentacyjna może złożyć się jako `Dumbbell Snatch`.

## Stan obecny

- `ExerciseType.resolve(rawName:)` rozpoznaje ruch oraz opcjonalny sprzęt z nazwy.
- `ExtractedWorkout+Mapper` przekazuje wykryty sprzęt do `ExerciseSession`.
- `ExerciseSession` i `ExerciseSessionDraft` przechowują `Equipment?`.
- `ExerciseEditorView` pokazuje typ ruchu, cel, ciężar i notatki, ale nie ma wiersza sprzętu.
- `ExerciseSession.displayName` uwzględnia jawnie przechowany sprzęt względem domyślnego sprzętu ruchu.
- rematch katalogu może aktualizować sprzęt na podstawie nazwy; trzeba sprawdzić i zagwarantować, że nie nadpisze jawnej decyzji użytkownika.
- wynik treningu i log mają pole sprzętu, a IOS-00136 naprawił jego zapis. Nie ma obecnie ścieżki do korekty sprzętu przy edycji samego wyniku.

## Zakres

### W zakresie

1. Jawny wybór sprzętu w edytorze ćwiczenia planu — zarówno przy tworzeniu, jak i edycji ćwiczenia.
2. Widoczny sprzęt w podglądzie skanu oraz w podglądach i szczegółach zapisanych planów.
3. Zachowanie wyboru w draftach, modelu planu, kodowaniu JSON i istniejącym przepływie do treningu oraz logu.
4. Semantyka jawnego wyboru kontra wartość wywnioskowana/domyslna; brak sprzętu musi być możliwy do wybrania.
5. Testy mapowania, aktualizacji draftu, rematchu i round-trip persystencji planu/logu.
6. Lokalizacja nazw sprzętu i kontrolki w językach wspieranych przez aplikację.

### Poza zakresem tej iteracji

- Edycja tożsamości ćwiczenia i sprzętu w już zapisanym historycznym logu.
- Wybór dodatkowych akcesoriów (pas, owijki, paski); obecny `Equipment` opisuje główny implement, nie akcesoria.
- Przebudowa katalogu ruchów, w tym usunięcie ewentualnego dublowania `snatch` / `dumbbellSnatch`.
- Zmiana sposobu rozpoznawania tekstu przez model, poza prezentacją i korektą wyniku.

## Decyzje domenowe do przyjęcia w implementacji

Obecne `Equipment?` nie odróżnia trzech stanów: nie wykryto, użyj domyślnego oraz użytkownik jawnie wybrał „bez sprzętu”. UI nie powinno opierać się na samym `nil`.

Preferowany model: jawna wartość override z trzema stanami, np. `inherit` (użyj sprzętu wykrytego/domyslnego), `none` (użytkownik potwierdził brak) i `equipment(Equipment)`. Jeśli kompatybilność istniejącego JSON przemawia za pozostawieniem pola `equipment`, dodać opcjonalny marker źródła/override i zdekodować stare rekordy jako `inherit`. Nie zmieniać znaczenia historycznego `nil` bez migracji lub kompatybilnego dekodera.

Semantyka:

- wartość automatyczna jest podpowiedzią i może być odświeżona przez rematch katalogu;
- jawna decyzja użytkownika wygrywa z rematchem;
- „Automatycznie” pozwala wrócić do wyniku katalogu;
- „Brak sprzętu” jest różne od „Automatycznie”, które akurat nie znalazło sprzętu.

## Fazy implementacji

### 1. Domena i zachowanie rematchu

- Przejrzeć `ExerciseSession`, `ExerciseSessionDraft`, `TrainingSession+CatalogRematch` i `ExerciseCatalogClient.rematchIfNeeded`.
- Dodać reprezentację jawnego override'u z kompatybilnym dekodowaniem starych planów.
- Zdefiniować computed value dla sprzętu efektywnego: jawny override → wykryty sprzęt → domyślny sprzęt ruchu.
- Upewnić się, że rematch aktualizuje automatyczne rozpoznanie, ale zachowuje override użytkownika.
- Dodać testy stary JSON, trzech stanów, rematchu i przykładów `Snatch` / `Dumbbell Snatch`.

### 2. Edytor ćwiczenia

- Dodać wiersz „Sprzęt” w `ExerciseEditorView` w grupie ćwiczenia, bezpośrednio przy wyborze ruchu.
- Udostępnić „Automatycznie”, „Brak” i przypadki `Equipment.allCases`.
- Wartość początkowa ma pokazywać to, co rozpoznał skaner lub sugeruje katalog, ale pozostawać odróżnialna od jawnego wyboru.
- Zmiana typu ruchu nie może po cichu kasować ręcznego override'u; jeśli sprzęt staje się niezgodny, zachować go do decyzji użytkownika albo jawnie wrócić do „Automatycznie” zgodnie z ustaloną regułą domenową.
- Zapisać zmianę przez `ExerciseEditorFeature` i delegate `saved`, bez tworzenia nowego ID ćwiczenia.

### 3. Widoczność w podglądach i szczegółach planu

- Wspólny `WorkoutDetailContent` pokazuje sprzęt przy nazwie ćwiczenia, jeśli wynika z jawnego wyboru lub zmienia domyślną nazwę.
- Podgląd po skanowaniu ma pokazywać wynik mapowania; wiersz ćwiczenia otwiera edytor korekty, jeśli przepływ podglądu może bezpiecznie delegować edycję. W przeciwnym razie dodać oczywiste wejście „Edytuj ćwiczenia” do istniejącego edytora planu.
- Puste „Automatycznie” bez wykrytego sprzętu nie dodaje pustej etykiety.
- Sprawdzić też szczegóły planu i template preview, które współdzielą `WorkoutDetailContent`.

### 4. Propagacja do wyniku treningu

- Prześledzić kopiowanie `ExerciseSession` → dane sesji → `ExerciseLogInput` → `ExerciseLog`/record.
- Jeśli użytkownik zmienia sprzęt w planie, wynik i log używają efektywnego wyboru.
- Jeśli model danych historycznego logu ma zachować informację o ręcznym wyborze, dodać kompatybilne pole źródła/override; jeśli wystarczy utrwalić efektywny sprzęt dla analityki, jasno udokumentować utratę informacji o pochodzeniu.
- Nie pozwolić, by domyślna sztanga błędnie wymuszała wagę po jawnym wyborze „Brak”.
- Aktualizacja rekordu ma zachować equipment (regresja IOS-00136).

### 5. Lokalizacja i wykończenie

- Dodać lokalizowane etykiety: „Sprzęt”, „Automatycznie”, „Brak”, nazwy opcji.
- Wykorzystać istniejące `Equipment.displayName`.
- Sprawdzić długie nazwy, dostępność VoiceOver i edycję na małych ekranach.

## Kryteria akceptacji

1. Po zeskanowaniu „Dumbbell Snatch” podgląd ujawnia rozpoznany wariant/sprzęt.
2. Użytkownik może w edytorze planu zmienić hantle na sztangę, inny sprzęt, „Brak” lub wrócić do „Automatycznie”.
3. Zmiana jest widoczna po zapisaniu planu, ponownym otwarciu aplikacji i ponownym rematchu katalogu.
4. Ręczny wybór nie jest nadpisywany przez automatyczny rematch.
5. Edytor wyniku korzysta ze sprzętu efektywnego przy nazwie oraz decyzji o polu ciężaru; jawny „Brak” ma pierwszeństwo nad domyślnym sprzętem ruchu.
6. Sprzęt pozostaje poprawny w zapisanym logu i analityce po round-trip przez bazę.
7. Stare zapisane plany i logi dekodują się bez utraty danych.
8. Matcher nadal preferuje dokładne dopasowanie ruchu przed fallbackiem usuwającym token sprzętu; osobny case `dumbbellSnatch` pozostaje zachowany w tej iteracji.

## Pliki i obszary do sprawdzenia

- `SharedModels/.../TrainingSession/TrainingSession.swift`
- `SharedModels/.../TrainingSession/ExerciseSessionDraft.swift`
- `SharedModels/.../TrainingSession/TrainingSession+CatalogRematch.swift`
- `SharedModels/.../ExtractedWorkout/ExtractedWorkout+Mapper.swift`
- `SharedModels/.../SharedEnum/ExerciseType/ExerciseType.swift`
- `SharedModels/.../SharedEnum/Equipment/Equipment.swift`
- `WorkoutMirrorLive/.../ExerciseEditor/Feature/ExerciseEditorFeature+State.swift`
- `WorkoutMirrorLive/.../ExerciseEditor/Feature/ExerciseEditorFeature+Action.swift`
- `WorkoutMirrorLive/.../ExerciseEditor/Feature/ExerciseEditorFeature.swift`
- `WorkoutMirrorLive/.../ExerciseEditor/ExerciseEditorView.swift`
- `WorkoutMirrorLive/.../Plans/Shared/WorkoutDetailContent.swift`
- `WorkoutMirrorLive/AppTabNew/Client/ExerciseCatalogClient.swift`
- przepływ `WorkoutResultsFeature`, `ExerciseLogInput`, `ExerciseLogClient` i `ExerciseLogRecord`

## Weryfikacja

- Testy SharedModels: mapowanie, effective equipment, jawny brak, zachowanie override przy rematchu, zgodność starych payloadów.
- Testy AppDatabase: round-trip sprzętu i kompatybilność migracji, jeżeli zmieni się rekord.
- Weryfikacja UI na symulatorze: skan → podgląd → korekta → zapis planu → ponowne otwarcie → wpisanie wyniku → historia/analityka.
- Ręcznie sprawdzić przypadki: `Snatch`, `Dumbbell Snatch`, `DB Snatch`, nieznany ruch ze słowem „dumbbell”, ruch bez domyślnego sprzętu i jawny brak.

## Ryzyka

- Zmiana semantyki `nil` może zmienić zachowanie starych planów; wymagana zgodność dekodowania.
- Pole `equipment` w logu może dziś przechowywać tylko efektywny sprzęt, bez informacji czy wybrał go model czy użytkownik.
- Model katalogu ma osobne `dumbbellSnatch` oraz może też reprezentować `snatch` + dumbbell. UI musi pokazywać oba wymiary bez sugerowania, że są tym samym rekordem domenowym.
- Lista `Equipment` jest ograniczona do czterech implementów. Nie dodawać „bodyweight” jako Equipment; jawny brak ma osobną semantykę.
