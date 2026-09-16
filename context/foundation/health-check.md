---
project: MyFitnessJournal (StepTrackerTCA)
checked_at: 2026-08-28T16:00:00+02:00
health_status: healthy
context_type: brownfield
language_family: swift
stack_assessment_available: true
checks_run:
  - lockfile
  - dependency_audit
  - outdated_deps
  - test_runner
  - ci_cd
  - configuration
audit_findings:
  critical: 0
  high: 0
  moderate: 0
  low: 0
test_runner_detected: true
ci_provider: null
recommended_fixes: 6
---

## Dependency Health

### Lockfile

Status: present (`Package.resolved`, 11 KB — `MyFitnessJournal.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/`)
Package manager: Swift Package Manager (SPM)

Wersje przypięte per commit/wersja — buildy reprodukowalne.

### Security Audit

Tool: skipped — no built-in audit tool for swift (SPM nie ma odpowiednika `npm audit`)
Recommended external tool: GitHub Dependabot (wspiera ekosystem SPM — alerty o podatnościach i PR-y aktualizacyjne po włączeniu w ustawieniach repo)
Summary: 0 CRITICAL, 0 HIGH, 0 MODERATE, 0 LOW (formalnie: brak danych z narzędzia)

Ocena jakościowa zamiast narzędzia: wszystkie zależności zewnętrzne pochodzą od dwóch aktywnie utrzymywanych wydawców (Point-Free, Apple), bez zależności przechodnich spoza tego kręgu. Sekrety: klucz Anthropic API wprowadzany przez użytkownika i przechowywany w Keychain (`APIKeyClient`, odczyt w call-time w `WorkoutExtractionClient.swift:39`) — brak hardcodowanych kluczy w kodzie (grep czysty).

### Outdated Dependencies

Packages with major version gaps: 0

Brak zaległości o całą wersję główną; zaległości minor (informacyjnie, stan na dziś):

- **sqlite-data**: 1.6.6 → 1.11.0 (5 wersji minor — największa zaległość; przejrzeć changelog PRZED migracją v12 planowaną w nadchodzącej pracy, żeby nie łączyć bumpa z nową tabelą w jednym kroku)
- **swift-dependencies**: 1.14.1 → 1.17.0
- **swift-navigation**: 2.10.2 → 2.11.0
- **swift-composable-architecture**: 1.26.0 → 1.26.1 (patch)
- **swift-sharing**: 2.9.0 → 2.9.1 (patch)
- **swift-snapshot-testing**: 1.19.2 → 1.19.4 (patch)

## Test Suite

Test runner: Swift Testing (natywny, Apple)
Tests found: 5 plików testowych w 1 pakiecie (SharedModels), m.in. golden testy katalogu ćwiczeń (85 przypadków)
Test execution: passing (`swift test --filter ExerciseTypeMatchingTests` — 4 testy zielone, potwierdzone 2026-08-27)

Configuration: `SharedModels/Package.swift` (testTarget `SharedModelsTests`)
Framework: Swift Testing (`import Testing`, `@Test`, `#expect`); w zależnościach też swift-snapshot-testing 1.19.2 (nieużywany aktywnie)

Pokrycie per pakiet: SharedModels ✓ · HealthHub ✗ · AppDatabase ✗ · Commons ✗ · PeerMirror ✗ — agent może weryfikować zmiany tylko w jednym z pięciu pakietów. Uwaga łagodząca: nadchodząca praca (silnik PR jako czysty pakiet) doda drugi testowany pakiet zgodnie z wzorcem SharedModels.

## CI/CD

Provider: not detected
Configuration: not found

ℹ No CI/CD configuration detected. You'll set this up in the infrastructure and deployment lesson.
For now, a local test runner is sufficient for agent collaboration.

Nota kontekstowa: pakiety SPM tego repo (SharedModels, przyszły silnik PR) są testowalne przez `swift test` na runnerze macOS bez podpisywania kodu — pierwszy pipeline będzie tani (jeden job, 2–3 min).

## Configuration

### High severity

(brak)

### Medium severity

- **`.swiftformat` / `.swiftlint.yml`** — brak narzędzia formatowania/lintowania; spójność stylu wyjścia agenta opiera się wyłącznie na konwencjach spisanych w CLAUDE.md (działa, ale nie jest egzekwowane mechanicznie). Fix: decyzja świadoma — jeśli chcesz egzekwowania: `brew install swiftformat && echo "--swiftversion 6" > .swiftformat`; jeśli nie — udokumentowana rezygnacja też jest OK (konwencje CLAUDE.md + code review pokrywają realny problem).

### Low severity

- **`.editorconfig`** — spójność wcięć/końców linii między edytorami. Fix: 5-liniowy plik (root=true, utf-8, lf, indent 4).
- **`MyFitnessJournal.xcodeproj/project.pbxproj.backup` i `.bak`** — śmieciowe kopie zapasowe w repo; szum dla agenta i ryzyko edycji złego pliku. Fix: `git rm 'MyFitnessJournal.xcodeproj/project.pbxproj.backup' 'MyFitnessJournal.xcodeproj/project.pbxproj.bak'` + wpis `*.pbxproj.backup` / `*.pbxproj.bak` w `.gitignore`.

Obecne i poprawne: `.gitignore` ✓, pliki instrukcji agenta (`CLAUDE.md` root-drogowskaz + `WorkoutMirrorLive/CLAUDE.md` 270 linii) ✓, klucz API w Keychain (odpowiednik `.env` niepotrzebny) ✓, `Localizable.xcstrings` jako jedyne źródło tłumaczeń ✓.

## Stack Assessment Cross-Reference

Stack assessment: context/foundation/stack-assessment.md
Agent readiness (from stack-assess): ready-with-compensation

| Luka bramy jakości                                | Ustalenie health-check                                             | Status      |
|---------------------------------------------------|--------------------------------------------------------------------|-------------|
| training data: SQLiteData/TCA-1.26/Swift Testing   | Wpisy kompensacyjne ISTNIEJĄ (3 dodatki z oceny wdrożone i zacommitowane w 998ee69) | Mitigated   |
| brak CI/CD (luka 2 z oceny)                        | Potwierdzone: zero konfiguracji; tanie wejście przez `swift test` pakietów | Reinforced (kategoria B) |
| brak drogowskazu w korzeniu (luka 3 z oceny)       | Root `CLAUDE.md` istnieje (dodany w ramach oceny stacku)            | Mitigated   |
| typed: pass (Swift 6)                              | Typy egzekwowane przez kompilator przy każdym buildzie — CI nie jest potrzebne do type-checku | n/d (mocna strona) |

## Recommended Fixes

### Fix before agent work (Category A)

### 1. Usunięcie śmieciowych kopii pbxproj

**Impact**: agent przeszukujący projekt widzi trzy warianty pbxproj — ryzyko czytania/edycji nieaktualnego pliku i fałszywych trafień grep.
**Severity**: low
**Effort**: quick (< 5 min)
**Fix**:

```bash
git rm "MyFitnessJournal.xcodeproj/project.pbxproj.backup" "MyFitnessJournal.xcodeproj/project.pbxproj.bak"
printf '*.pbxproj.backup\n*.pbxproj.bak\n' >> .gitignore
```

### 2. Przegląd changelog sqlite-data 1.6.6 → 1.11.0

**Impact**: nadchodząca praca dodaje migrację v12 — robienie tego na bibliotece 5 wersji minor za najnowszą oznacza, że ewentualny późniejszy bump zmiesza się ze świeżą migracją; przegląd TERAZ pozwala świadomie zdecydować: bump przed v12 albo jawne odroczenie.
**Severity**: medium
**Effort**: moderate (15–30 min)
**Fix**: przeczytać release notes 1.7–1.11 (github.com/pointfreeco/sqlite-data/releases); decyzja bump/defer zapisana jedną linią w planie implementacji.

### 3. Decyzja: formatter (SwiftFormat) — tak czy świadome nie

**Impact**: bez mechanicznego egzekwowania stylu spójność wyjścia agenta zależy od CLAUDE.md i review; działa dziś, ale nie skaluje się na dłuższe sesje agentowe.
**Severity**: medium
**Effort**: moderate (15–30 min) albo świadoma rezygnacja (0 min)
**Fix**: `brew install swiftformat && echo "--swiftversion 6" > .swiftformat && swiftformat --lint .` — albo dopisek w CLAUDE.md „formatter: świadomie brak, konwencje egzekwuje review".

### 4. Testy dla AppDatabase (przy okazji v12, nie wcześniej)

**Impact**: pakiet z migracjami bazy nie ma żadnego testu — agent zmieniający schemat nie może zweryfikować migracji; nadchodząca migracja v12 to naturalny moment na pierwszy test (in-memory DB, migrate, asercja schematu).
**Severity**: medium
**Effort**: significant (> 1 godzina, ale współdzielony z planowaną pracą)
**Fix**: przy migracji v12 dodać `testTarget` do `AppDatabase/Package.swift` + test „migrator przechodzi v1→v12 na pustej bazie in-memory".

### Addressed in upcoming lessons (Category B)

### Brak potoku CI/CD

**Lesson**: [Sprint Zero z Agentem: infrastruktura, walking skeleton i pierwszy deploy (M1L5)](https://platforma.przeprogramowani.pl/external/10xdevs-3/m1-l5)
**What you'll do there**: skonfigurujesz pierwszy pipeline — dla tego repo naturalny kształt to GitHub Actions z jobem `swift test` na pakietach SPM (runner macOS, bez podpisywania), rozszerzalny o build aplikacji.

### Onboarding agenta (AGENTS.md / przegląd reguł)

**Lesson**: [Agent Onboarding: Agents.md, AI Rules i feedback loops (M1L4)](https://platforma.przeprogramowani.pl/external/10xdevs-3/m1-l4)
**What you'll do there**: przegląd i scoring istniejących plików instrukcji (`/10x-rule-review`) — repo już ma mocny CLAUDE.md, więc to będzie audyt, nie tworzenie od zera.

### Konfiguracja deploymentu

**Lesson**: M1L5 (jak wyżej)
**What you'll do there**: dziś deploy = ręczne archiwum + TestFlight (działa, sprint wydaniowy 0.6 przeszedł wczoraj); lekcja pomoże zdecydować, czy automatyzować (fastlane/xcodebuild w CI) — dla solo-projektu ręczny proces może pozostać świadomym wyborem.

## Summary

Health status: healthy

Projekt jest w dobrej kondycji operacyjnej: zależności przypięte lockfilem i pochodzące od dwóch zaufanych wydawców (zero zaległości major), sekrety poprawnie w Keychain, działający nowoczesny runner testów z zielonym przebiegiem, a pliki instrukcji agenta — wraz z kompensacjami z oceny stacku — są już wdrożone i zacommitowane. Realne luki są niewielkie i punktowe: brak mechanicznego formattera (decyzja do podjęcia), testy tylko w jednym z pięciu pakietów (plan naprawczy naturalnie sprzężony z nadchodzącą migracją v12) i dwa śmieciowe pliki backup w repo.

Next step: wykonaj szybkie poprawki kategorii A (#1 od ręki, #2–#4 przy planie implementacji), a następnie przejdź do onboardingu agenta (M1L4) — obie ścieżki łańcucha zbiegają się tam z kompletem artefaktów kontekstu.
