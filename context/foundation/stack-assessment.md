---
project: MyFitnessJournal (StepTrackerTCA)
assessed_at: 2026-08-28T00:00:00+02:00
agent_readiness: ready-with-compensation
context_type: brownfield
stack_components:
  language: Swift 6
  framework: SwiftUI + The Composable Architecture 1.26.0
  build_tool: Xcode (xcodebuild) + Swift Package Manager
  test_runner: Swift Testing (+ swift-snapshot-testing 1.19.2)
  package_manager: SPM
  ci_provider: null
  deployment_target: TestFlight / App Store
gates_passed: 14
gates_failed: 1
---

## Stack Components

- **Język: Swift 6** — pakiety deklarują `swift-tools-version: 6.2`; projekt działa w trybie strict concurrency (konwencja `defaultIsolation(MainActor.self)`, `Sendable` egzekwowane). Wpis `SWIFT_VERSION = 5.0` w pbxproj dotyczy legacy targetu i nie odzwierciedla realnego trybu pakietów.
- **Framework: SwiftUI + TCA 1.26.0** — pełny ekosystem Point-Free: swift-dependencies 1.14.1, swift-sharing 2.9.0, swift-navigation 2.10.2, swift-perception 2.0.10 (Package.resolved).
- **Persystencja: SQLiteData 1.6.6** — makro `@Table`, `DatabaseMigrator`, migracje append-only v1–v11 (`AppDatabase/Sources/AppDatabase/Schema.swift`).
- **Build: Xcode + SPM** — `MyFitnessJournal.xcodeproj` + 5 lokalnych pakietów (SharedModels, HealthHub, AppDatabase, Commons, PeerMirror).
- **Testy: Swift Testing** — 5 plików testów w `SharedModels/Tests/` (`import Testing`, zero XCTest w aktywnym kodzie); golden testy katalogu ćwiczeń jako wzorzec domowy.
- **CI/CD: brak** — brak `.github/workflows/`, fastlane i jakiejkolwiek automatyzacji builda/testów.
- **Deployment: TestFlight/App Store** — signing w pbxproj (rozdział kont per branch develop/release), bez plików konfiguracyjnych deploymentu.
- **Pliki instrukcji: `WorkoutMirrorLive/CLAUDE.md` (264 linie)** + globalny `~/CLAUDE.md` + zestaw skilli użytkownika (pfw-*, axiom-*) — patrz „istniejąca kompensacja".

## Quality Gate Assessment

| Komponent            | Typed | Konwencje | Training Data | Dokumentacja | Werdykt |
|----------------------|-------|-----------|---------------|--------------|---------|
| Swift 6 (język)      | ✓     | —         | —             | —            | pass    |
| SwiftUI + TCA 1.26   | —     | ✓         | ~             | ✓            | pass z notą |
| SQLiteData 1.6       | —     | ✓         | ✗             | ✓            | fail → kompensowane |
| Xcode + SPM          | —     | ✓         | ✓             | ✓            | pass z notą |
| Swift Testing        | —     | —         | ~             | ✓            | pass z notą |

### Gate Details

**Typed — pass.** Swift jest statycznie typowany; tryb Swift 6 dokłada egzekwowaną izolację aktorów i `Sendable`. Kontrakty projektu są typowane end-to-end: `@Table` (schemat bazy w typach), `@Reducer`/`@ObservableState` (stan i akcje), `@DependencyClient` (granice zależności). Dowód: `SharedModels/Package.swift` (`swift-tools-version: 6.2`), makra w `AppDatabase/Sources/AppDatabase/Records/*.swift`.

**Convention-based — pass.** TCA to jeden z najbardziej opiniotwórczych frameworków w ekosystemie (Reducer/State/Action/Store), a projekt dokłada własne, spisane konwencje: struktura folderów per feature (Feature/View/Client/Child/Enum/Utilities), twarde reguły TCA (@Presents zamiast StackState, @ViewAction, zakaz @State w View), wzorzec Client/Service, multicast AsyncStream, reguły R1–R9 dla HealthKit. Dowód: `WorkoutMirrorLive/CLAUDE.md` §„Konwencja folderów per feature", §„TCA — twarde konwencje".

**Popular in training data — oceniane per rodzina języka (Swift):**
- SwiftUI: mainstream w danych treningowych — pass.
- TCA: popularny w Swift OSS, ale **API 1.26 (@Reducer, @ObservableState, store.send) jest nowsze niż większość korpusu** — agent bez sterowania dryfuje do legacy idiomów (ViewStore, WithViewStore, pullback). Częściowy pass.
- SQLiteData: biblioteka z 2025 — **fail** (nawet w rodzinie Swift to nowość; agent konfabuluje API albo miesza z GRDB/CoreData).
- Swift Testing: framework z 2024 — częściowy pass (agent bez sterowania pisze XCTest).
- Xcode+SPM: wszechobecne — pass; nota: `project.pbxproj` jest agent-wrogi jako format (nieczytelny, konfliktogenny).

**Well-documented — pass.** Apple: dokumentacja wersjonowana (SwiftUI, HealthKit, Swift Testing). Point-Free: DocC + przewodniki migracji per wersja dla TCA i SQLiteData. Dowód: oficjalne strony dokumentacji obu wydawców, wersjonowane.

## Gaps & Compensation

### Luka 1: SQLiteData / TCA-1.26 / Swift Testing nowsze niż korpus treningowy (brama 3)

Dlaczego to ważne: agent generujący kod „z pamięci" będzie produkował przestarzałe idiomy (ViewStore, XCTest, wymyślone API bazy), które kompilują się połowicznie i kosztują cykle korekt.

**Kompensacja — w większości JUŻ ISTNIEJE (to główne odkrycie tej oceny):**
- `WorkoutMirrorLive/CLAUDE.md` nakazuje uruchamiać skill `pfw-composable-architecture` przy nowych feature'ach i spisuje twarde konwencje TCA z zakazami legacy wzorców.
- Zestaw skilli użytkownika pokrywa dokładnie te trzy luki: `pfw-composable-architecture`, `pfw-sqlite-data`, `pfw-testing` (+ `pfw-dependencies`, `pfw-modern-swiftui`) — to żywa, aktualizowana dokumentacja wzorców w miejscu, gdzie agent jej szuka.
- Sekcja „Pułapki które już Cię ugryzły" i wzorce multicast/R1–R9 kodyfikują wiedzę, której nie ma w żadnym korpusie.

Ocena szczerości: bez tych plików werdykt brzmiałby `significant-friction`; z nimi realne tarcie jest niskie i dotyczy głównie nowych obszarów API.

### Luka 2: brak CI/CD

Żaden pipeline nie buduje projektu ani nie uruchamia testów automatycznie — jakość zależy od dyscypliny lokalnej. To temat następnego kroku (`/10x-health-check`) i twardy wymóg nadchodzącej pracy; odnotowane tu dla ciągłości łańcucha. Mitygująca okoliczność: czyste pakiety SPM (SharedModels z testami; planowany silnik PR) są testowalne przez `swift test` na runnerze macOS bez podpisywania — niski próg wejścia dla pierwszego pipeline'u.

### Luka 3 (drobna): brak pliku instrukcji na poziomie korzenia repo

`CLAUDE.md` żyje w `WorkoutMirrorLive/` (świetny, ale target-scoped). Agent startujący w korzeniu repo (np. w CI albo w innym targecie) nie dostaje wskazania, gdzie są konwencje.

### Recommended Instruction File Additions

Gotowe do wklejenia — trzy uzupełnienia:

**1. Do `WorkoutMirrorLive/CLAUDE.md`, sekcja „TCA — twarde konwencje" (jawne zakazy legacy API):**

```markdown
- **TCA 1.26 — wyłącznie nowoczesne API:** `@Reducer`, `@ObservableState`, `store.send`,
  `@Bindable var store`. ZAKAZANE legacy: `ViewStore`, `WithViewStore`, `pullback`,
  `IfLetStore`, `SwitchStore`, `TaskResult` — jeśli generujesz któreś z nich,
  zatrzymaj się i wczytaj skill `pfw-composable-architecture`.
```

**2. Do `WorkoutMirrorLive/CLAUDE.md`, sekcja „Build & run" (testy):**

```markdown
- **Testy: wyłącznie Swift Testing** (`import Testing`, `@Test`, `#expect`) — NIE XCTest.
  Wzorzec: golden testy w `SharedModels/Tests/SharedModelsTests/ExerciseTypeMatchingTests.swift`.
  Uruchamianie: `cd <pakiet> && swift test` (pakiety SPM nie wymagają symulatora).
```

**3. Nowy plik `CLAUDE.md` w korzeniu repo (drogowskaz, nie duplikacja):**

```markdown
# StepTrackerTCA (MyFitnessJournal) — drogowskaz

Konwencje projektu i architektura: **`WorkoutMirrorLive/CLAUDE.md`** (źródło prawdy —
przeczytaj przed jakąkolwiek zmianą). Główny target: `WorkoutMirrorLive/`;
pakiety SPM: SharedModels, HealthHub, AppDatabase, Commons, PeerMirror.
Legacy (nie tykać): `StepTrackerTCA/`, `Features/`. Artefakty procesu: `context/`.
Build: `MyFitnessJournal.xcodeproj`, scheme `WorkoutMirrorLive`; testy pakietów: `swift test`.
```

## Summary

**Werdykt: ready-with-compensation** — z zastrzeżeniem, że lwia część kompensacji już istnieje i działa (264-liniowy CLAUDE.md z twardymi konwencjami + komplet skilli Point-Free). Stack jest mocno typowany i skrajnie konwencjonalny — dwie bramy, które dla agenta znaczą najwięcej — a jedyna realna słabość (nowość TCA 1.26 / SQLiteData / Swift Testing względem korpusu treningowego) jest już załatana instrukcjami; pozostają trzy drobne uzupełnienia wskazane wyżej.

Kluczowe mocne strony: typowanie end-to-end (język + makra), konwencje spisane i egzekwowane, dokumentacja obu wydawców wersjonowana, czyste pakiety SPM testowalne bez symulatora.

Kluczowe luki: brak CI/CD (następny krok jej dotknie wprost), brak drogowskazu w korzeniu repo.

Następny krok: `/10x-health-check` — audyt zdrowia zależności, testów i pokrycia CI/CD.
