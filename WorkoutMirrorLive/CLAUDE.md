# WorkoutMirrorLive — instrukcje dla Claude

Główny target iOS aplikacji **MyFitnessJournal** (repo: `StepTrackerTCA`). Ten plik jest komplementarny do globalnego `~/CLAUDE.md` — nie powtarza ogólnych zasad (język polski, czytanie przed edycją, minimalne zmiany, konwencje istniejące).

## O projekcie

**MyFitnessJournal** to aplikacja fitness na **iOS + Apple Watch + widgety** do strukturalnego trackingu treningów (siłówka, CrossFit, WOD-y). Inspirowana kursem Sean Allen StepTracker, przepisana na nowoczesny stack: **TCA + SwiftUI + SQLiteData + HealthKit + CloudKit + Claude API**.

### Kluczowe capabilities (z perspektywy użytkownika)

- **Skanowanie planów treningowych (OCR + AI)** — user fotografuje notatnik z planem; OCR + Claude API (`claude-sonnet-4-5`) produkuje strukturalny `TrainingSession` z WOD-ami, `ExerciseType`, `[PlannedSet]` i sugerowaną wagą.
- **Live workout session na Apple Watch** — timer, strefy HR, countdown, controls, Live Activity, sync z iPhone w czasie rzeczywistym.
- **Per-set strength tracking** — w Summary po treningu user wpisuje rzeczywiste `reps × weight` per set (np. plan `5×5 @ 80kg` → 5 input rows z osobnym `SetEntry`).
- **Activity Details + plan mirror** — historia treningów z HealthKit zmatchowana z odpowiadającym planem; per-WOD score (`forTime` / `forLoad` / `AMRAP` / `completed`), edytowalne w oknie 24h po treningu.
- **Exercise Analytics** — wykresy postępu per ćwiczenie: 1RM, volume load, tempo, PR streaks, scaling progression.
- **Training Readiness** — dzienny score `-10…+5` z 4 komponentów (RHR, HRV, sleep, activity load) z wyjaśnieniem każdego.
- **Health metrics summary** — Apple Watch rings, daily stats, heart rate trends, sleep summary.
- **CloudKit sync** — pełna persystencja via SQLiteData + `CloudKitSyncable` protocol.

## Targety w workspace

- **`WorkoutMirrorLive/`** ← **TEN target.** iPhone app: pełny UI, wszystkie feature'y TCA, lokalizacja, app shell, entry point (`WorkoutMirrorLiveApp.swift`).
- **`WorkoutMirror Watch App/`** — Apple Watch companion: live workout session (HR, timer, controls, Live Activity).
- **`MyFitnessJournal Watch App/`** — alternatywny / historyczny watch target (sprawdź zanim coś dotkniesz).
- **`WorkoutSessionWidget/`** — Home Screen widgets + Live Activities: `TimerLiveActivity`, `TrainingReadinessWidget`, `WorkoutMetricsView`, `WorkoutSessionLive`.

## Stack technologiczny

- **Swift 6** (strict concurrency), **SwiftUI** (iOS 18+).
- **[TCA](https://github.com/pointfreeco/swift-composable-architecture)** — Point-Free, główny architectural framework.
- **[SQLiteData](https://github.com/pointfreeco/swift-sqlite-data)** — Point-Free, `@Table` makro, `DatabaseMigrator`, CloudKit sync via `CloudKitSyncable`.
- **HealthKit** — workouts, active energy, RHR, HRV, sleep analysis, background delivery (observer queries w `AppDelegate`).
- **CloudKit** — sync container `iCloud.com.ss.WorkoutMirrorLive`, App Group `group.com.ss.WorkoutMirrorLive`.
- **Claude API** — `claude-sonnet-4-5` dla parsowania zdjęć planu (via `ScanPlanClient`).
- **WidgetKit + ActivityKit** — Live Activities (workout session), Home Screen widgets (readiness, metrics).

## Build & run

- **Xcode project:** `MyFitnessJournal.xcodeproj` (NIE `StepTrackerTCA.xcodeproj` — to historyczne).
- **Default branch:** `develop`. Branche feature'owe: `dev/IOS-NNNNN/IOS-NNNNN`.
- **Build:** otwórz `MyFitnessJournal.xcodeproj`, wybierz scheme `WorkoutMirrorLive` (iOS) lub `WorkoutMirror Watch App`, Cmd+R.
- **DEBUG erases on schema change** — w `Schema.swift` ustawione `migrator.eraseDatabaseOnSchemaChange = true` dla DEBUG. Po zmianie migracji w DEBUG baza castuje się automatycznie. W RELEASE wymagana jest pełna `DatabaseMigrator` migracja (ALTER TABLE itp.).
- **Diagramy projektu:** `FeatureDiagram.md` (struktura features), `CoreDataDiagram.md` (schema; nazwa historyczna — projekt nie używa CoreData, używa SQLiteData).

## Architektura modułów

Projekt dzieli się na 3 części; ten target jest jedną z nich:

- **`WorkoutMirrorLive/`** ← **TU jesteś.** Główny target — UI, feature'y TCA, lokalizacja, app shell.
- **`SharedModels/`** — Swift Package: enumy, modele domenowe, klucze (np. `ViewState`, `ScanPlanViewState`).
- **`HealthHub/`** — Swift Package: serwisy zdrowotne, klienci HealthKit, kalkulacje (Training Readiness, BMR, Activity Rings).
- **`AppDatabase/`** — Swift Package: SQLite + migracje (SQLiteData / Point-Free).
- **`Commons/`** — Swift Package: utility (formattery, extensions niespecyficzne dla domeny).

## Struktura katalogów wewnątrz WorkoutMirrorLive

- **`FeaturesNew/`** — wszystkie utrzymywane feature'y. **Nowe ekrany / reducery dodawaj TYLKO tutaj.**
- **`Features/`** — **legacy**. Nie tykaj poza explicit ticketem migracyjnym. Jeśli musisz tu coś zmienić — najpierw zapytaj.
- **`AppScreen/`, `AppTab/`, `AppTabNew/`** — top-level shell + routing między tabami. `AppTabNew/` jest aktualny.
- **`UI/`** — reusable view components: modifiers, `styledGroupBox()`, custom controls.
- **`Utilities/`** — drobne helpery niespecyficzne dla featurów.
- **`Assets.xcassets/`** — kolory, ikony.
- **`Localizable.xcstrings`** — **jedyne** źródło tłumaczeń (xcstrings catalog, nie `.strings`).

## Konwencja folderów per feature

Każdy feature w `FeaturesNew/` trzyma się tej struktury:

```
FeatureName/
├── Feature/             # Reducer.swift, opcjonalnie Reducer+State.swift / Reducer+Action.swift
├── View/                # FeatureView.swift (czasem inline w Feature/)
├── Client/              # @DependencyClient + liveValue/testValue/previewValue
├── Child/               # zagnieżdżone subfeatury rekurencyjnie tym samym wzorcem
├── Enum/                # enumy specyficzne dla featura
└── Utilities/           # helpery w obrębie featura
```

Hierarchia ekranów = hierarchia folderów. Subfeature siedzi w `Child/<NazwaSubfeatury>/` rodzica.

## TCA — twarde konwencje

- **Nawigacja:** `@Presents` + `enum Destination` w State. NIE używaj `StackState` / `Path`.
- **Akcje z View:** `@ViewAction(for: FeatureName.self)` + `send(.viewAction)`. Brak bezpośredniego `store.send`.
- **Brak `@State` w View** — cały stan w TCA Store. View ma tylko `@Bindable var store: StoreOf<...>`.
- **State i `Equatable`** — pomiń `: Equatable` gdy stan zawiera typy nie-Equatable (np. `PhotosPickerItem`).
- **PhotosPicker** — używaj modifiera `.photosPicker(isPresented:selection:)` + `onChange`. NIE używaj view'a `PhotosPicker` z `@State`.

Przy nowych feature'ach **uruchom skill `/pfw-composable-architecture`** żeby wczytać aktualne wzorce Point-Free.

## TCA Dependencies — Client / Service pattern

- **Client** (`struct` z closure properties, zwykle z `@DependencyClient`) = dependency boundary. Wstrzykiwany przez `@Dependency(\.xxxClient)`.
- **Service** (`actor` / `final class`) = implementacja, ukryta za clientem. **NIE jest dependency** sam w sobie.
- **`liveValue`** ze service'em → `static let` (singleton, jedna instancja service'a per proces).
- **`testValue` / `previewValue`** → `static var` computed (nowa instancja per call jest OK i często pożądana).
- Reużycie w innym kliencie → wstrzyknij **client** przez `@Dependency` w `liveValue`, nie service.

### Pułapki które już Cię ugryzły

- **`@DependencyClient` gubi `Data` w closure** — workaround: ręczny struct bez makra.
- **`store.color.gradient` wewnątrz `PhotosPicker`** → Swift 6 `@MainActor` warning.
- **SQLiteData `try?` w preview** — używaj `try!` w preview helpers, `try?` połknie błąd migracji.
- **Stored `AsyncStream` w Service = bug czekający na ujawnienie** — drugi `for await` (TCA cancel + restart, view remount) nic nie dostaje. Patrz sekcja "AsyncStream — multicast pattern" niżej.

## AsyncStream — multicast pattern

> `AsyncStream` ma **jednego iteratora**. Drugi `for await` na tym samym stream'ie cisza. W TCA gdzie views remountują a effects są cancellowane — **stored single-stream = bug czekający na ujawnienie**.

- **Default dla streamów wystawianych przez Service = multicast**: `[UUID: Continuation]` dict + `broadcast()` helper + `onTermination` cleanup
- **Stored single-stream OK** tylko gdy krótko-żyjący lub jeden subscriber known-at-design-time. Inaczej → multicast.
- **Closure z BLE/HK delegate callback** — różne wątki → `Task { @MainActor in self?.broadcast(event) }` hop
- **Przykłady poprawnego multicast w projekcie:**
  - `DefaultTrainingManager.workoutMetricsStream` — Watch HR
  - `iPhoneWorkoutSession.metrics` — HK collected HR/calories
  - `PeerMirrorService.peerEventsStream` — peer events (od IOS-00094-I)
- **Red flag w code review:** `private let xxxStream: AsyncStream<T>` + `private let xxxContinuation: AsyncStream<T>.Continuation` jako stored properties → prawdopodobnie bug, sprawdź czy może być re-subskrybowany
- **Bug który to ujawnił (IOS-00094-I, 2026-06-07):** `PeerMirrorService.peerEventsStream` był stored. View remount w iPhone-standalone + Gym Room scenario (mode switch watchPrimary→iPhoneStandalone) powodował drugi `for await` cisza → user nie pojawiał się na iPadzie mimo BLE connect.
- **Pełny guide** (anty-pattern + pattern z kodem + audit checklist): memory `reference_async_stream_multicast.md`

## SwiftUI conventions

- **Button — zawsze verbose:**
  ```swift
  Button { action } label: { Text("...") }
  ```
  NIE `Button("label") { action }` (utrudnia lokalizację i refactor).
- **Wyciągaj buttony do `private var` / `private func`** zwracającego `some View`. Łatwiej testować snapshot i lokalizować.
- **Pętle — żadnych skrótów `i`/`j`/`k`.** Używaj `index`, `item`, lub nazw z domeny (`workout`, `exercise`).
- **Multi-line action closure → wyciągnij do `private func nameTapped()`.** W closure zostaje tylko `nameTapped()` lub `Task { await nameTapped() }`.
- **`.task { }`** — jednolinijkowo deleguj do `private func`. Nie inline'uj wielolinijkowej logiki w modifier.

## Lokalizacja

- **Wszystkie** user-facing stringi przez `String(localized: "klucz", bundle: .main)`.
- Tłumaczenia w `WorkoutMirrorLive/Localizable.xcstrings` (xcstrings catalog — Xcode UI edituje, nie ręcznie JSON).
- Komunikaty błędów też lokalizuj.
- Klucze: czytelne po angielsku (np. `"Edycja możliwa do %@"` jako klucz lub `"editable_until %@"` — trzymaj się konwencji istniejącej w xcstrings).

## HealthKit Workout Architecture — wytyczne iOS 26

> Aplikacja trzyma się sztywno wzorców iOS 26 / WWDC25 dla HealthKit workout.
> Wszystkie nowe zmiany w obszarze treningów MUSZĄ być z tym spójne. Jeśli
> planujesz refactor który łamie któryś z punktów — zatrzymaj się i zapytaj.

### Architektura — dwa równorzędne tory

Aplikacja wspiera dwa scenariusze sesji treningowej:

1. **Watch-initiated (Watch-primary + iPhone mirrored)**
   - Watch tworzy `HKWorkoutSession` jako primary.
   - `startMirroringToCompanionDevice()` propaguje sesję na iPhone.
   - HR z Watch sensora → iPhone przez `sendToRemoteWorkoutSession()`.
   - Pause/Resume/End z dowolnej strony, HealthKit syncuje automatycznie.

2. **iPhone-initiated (iPhone-primary z BLE HR sensor)**
   - iPhone tworzy `HKWorkoutSession` natywnie (iOS 26+).
   - `HKLiveWorkoutDataSource` automatycznie pairs sparowane BLE HR sensory (Polar, Wahoo, Powerbeats Pro 2).
   - Brak Watch app — opcjonalnie Watch tylko jako display.

Obie ścieżki używają tego samego stacka: `HKWorkoutSession` + `HKLiveWorkoutBuilder` + `HKLiveWorkoutDataSource`. Jeden abstract `WorkoutSession` protocol, dwie implementacje.

### Reguły niezmienne

**R1. `session.prepare()` PRZED `startMirroringToCompanionDevice()`**
Bez tego mirroring rozłącza się na iOS 26.0.1+ (Apple Developer Forums #804276). Po `prepare()` — 3-sekundowy countdown dla warmupu HR sensora.

**R2. `sendToRemoteWorkoutSession` dla state events i HR**
NIE używamy WatchConnectivity do pause/resume/end/HR podczas aktywnej sesji. WatchConnectivity zostaje TYLKO dla custom danych aplikacji (fazy treningu, notatki z planu, countdown). Powód: HealthKit channel działa nawet gdy `reachable=false`.

**R3. Crash Recovery przez Scene Delegate (iPhone)**
`UIScene.ConnectionOptions.shouldHandleActiveWorkoutRecovery` + `HKHealthStore.recoverActiveWorkoutSession`. ⚠️ Po recovery TRZEBA ponownie ustawić `builder.dataSource` — to się NIE zachowuje.

**R4. `session.end()` ZAWSZE — nawet jeśli `endCollection()` rzuca**
W przeciwnym razie `HKWorkoutSession` zostaje w zombie state i blokuje następny workout.

```swift
do { try await builder.endCollection(at: date) }
catch { /* log */ }
session.end()  // zawsze, poza do/catch
```

**R5. AsyncStream dla end-flow, nie polling**
`HKAnchoredObjectQueryDescriptor.results(for:)` (iOS 15.4+) — push-based `AsyncSequence`. NIE polling co 3s przez 30s.

**R6. `incomingWorkoutEventStream` jako computed property**
NIE stored. `AsyncStream` ma jednego iteratora; TCA cancellation + stored stream = drugi `for await` nic nie dostanie.

**R7. Reset state w `prepareWorkout()`**
`workoutSessionIsRunning`, `metrics`, wszelkie session-specific state MUSZĄ być reset w `prepareWorkout()` przed kolejnym treningiem.

**R8. Guard `nil` destination dla post-end events**
`transferUserInfo` ma guaranteed delivery — eventy (`workoutTick`) przychodzą jeszcze po końcu workoutu. Reducer musi guardować destination.

**R9. Cleanup outstanding WC transfers po activation (DEBUG-only)**
Po `activationDidCompleteWith(.activated)` w `DefaultWatchConnectivityManager` cancel `outstandingFileTransfers` starsze niż **24h** lub bez metadata `startedAt`. Wrapper `#if DEBUG` w ciele metody — bo jedyne `transferFile` w aplikacji idą przez `WorkoutFileLogger`, który sam jest `#if DEBUG`. Jeśli kiedyś dodamy file transfers w release builds — usuń `#if DEBUG` z `cleanupOutstandingTransfers`. Powód R9: `WCFileStorage` akumuluje ghost entries po crashach mid-transfer — bez cleanup'u widać setki linii `enumerateFileTransferResultsWithBlock could not load file data` w terminalu i powolny startup WC. Threshold 24h chroni świeże legitne transfery, ale eliminuje zalegające zombie entries.

```swift
for transfer in session.outstandingFileTransfers
    where transfer.file.metadata?["startedAt"].flatMap({ $0 as? Date })
        .map({ Date.now.timeIntervalSince($0) > 86_400 }) == true {
    transfer.cancel()
}
```

### iOS 26 features — NORMA dla nowych ekranów workout

Te API są wymagane w każdej nowej funkcji dotykającej workout:

- **App Intents** — Lock Screen control: `INStartWorkoutIntent`, `INPauseWorkoutIntent`, `INResumeWorkoutIntent`, `INEndWorkoutIntent`.
- **Live Activities** — Lock Screen + Dynamic Island podczas treningu (ActivityKit).
- **Smart Stack** (watchOS 26) — wymaga `HKWorkoutRouteBuilder` (outdoor) + accurate `HKWorkoutActivityType`.
- **Liquid Glass** — workout UI adoptuje nowy design system.

### Referencje

- WWDC25 #322 — Track workouts with HealthKit on iOS and iPadOS
- WWDC23 #10023 — Build a multi-device workout app
- Apple Developer Forums #804276 — iOS 26 mirroring bug
- Apple sample: `BuildingAWorkoutAppForIPhoneAndIPad.zip`

## ExerciseType catalog — nierozpoznane ćwiczenia (workflow)

Dopasowanie nazwa→enum dzieje się RAZ przy skanie planu i wynik jest zamrożony w bazie
(`ExerciseLogRecord.exerciseType`, plany w JSON blob `workoutsData`). Rozszerzenie katalogu
naprawia tylko przyszłe skany — przeszłość odzyskuje wyłącznie wersjonowany re-match.

**Workflow gdy pojawią się nowe nierozpoznane ćwiczenia:**
1. Radar: karta **"Unrecognized names"** (DEBUG-only, zostaje na stałe) w detalu
   „Unknown Exercise" (Statystyki → Ćwiczenia) — przycisk Copy kopiuje listę `nazwa<TAB>liczba`.
2. User wkleja listę do rozmowy z Claude → Claude rozszerza `ExerciseType` (aliasy do istniejących
   case'ów dla wariantów; nowe case'y dla odrębnych ruchów).
3. **Twarda reguła:** każde rozszerzenie cases/aliases MUSI w tym samym commicie bumpnąć
   `ExerciseType.catalogVersion` i dopisać nazwy do golden testów (`ExerciseTypeMatchingTests`).
4. Re-match (`ExerciseCatalogClient.rematchIfNeeded`, hook w `AppTabNewFeature.viewDidAppear`,
   guard `@Shared(.appStorage("exerciseCatalogRematchVersion"))`) odpala się przy następnym
   starcie apki i naprawia wstecz logi + plany. Idempotentny.

Uwagi: matcher = `ExerciseType.matched(fromRawName:)` (jedyne źródło dopasowania, Mapper deleguje);
w logach `unmatchedName` zostaje po re-matchu (proweniencja), w planach `customName` jest czyszczone
(invariant: tylko dla `.unknown`); kopie ExerciseSession/WorkoutSessionNew wyłącznie przez
identity-preserving inity z `TrainingSession+CatalogRematch.swift` (publiczne inity generują nowe UUID).

## Top-level pliki

- **`WorkoutMirrorLiveApp.swift`** — entry point. Bootstrap dependencies w `prepareDependencies { try $0.bootstrapDatabase() }`.
- **`AppDelegate.swift`** — background delivery dla Training Readiness (HealthKit observer queries).
- **`Info.plist`** — usage descriptions (HealthKit, Camera, PhotoLibrary).
- **`WorkoutMirrorLive.entitlements`** — capabilities: HealthKit, CloudKit, Background Modes, App Groups (`group.com.ss.WorkoutMirrorLive`).

## Workflow

- **Commity:** użytkownik commituje **zawsze sam**. Claude nigdy nie wywołuje `git commit` autonomicznie, nawet po większej refaktoryzacji.
- **Plany robocze:** zapisuj do `StepTrackerTCA/PLANS/IOS-NNNNN-<nazwa>.md`. Folder jest w `.gitignore`.
- **Branche:** konwencja `dev/IOS-NNNNN/IOS-NNNNN`.
- **Subtaski:** każdy = jeden atomowy commit (kompilujący się, logicznie zamknięty).

## Czego nie robić bez pytania

- Edytować plików w `Features/` (legacy).
- Modyfikować `Localizable.xcstrings` w innych językach niż polski/angielski.
- Dotykać `WorkoutMirrorLive.entitlements` ani `Info.plist` bez explicit potrzeby.
- Wprowadzać nowe `@State` w View'ach.
- Tworzyć dokumentację (`*.md`) bez prośby — chyba że to plan w `PLANS/`.
