# Deploy plan — pierwszy pipeline CI (GitHub Actions)

> Artefakt „Plan Mode": zatwierdzony plan pierwszego wdrożenia infrastruktury CI,
> wg `context/foundation/infrastructure.md` (decyzja: GitHub Actions) i
> `stack-assessment.md`. Zakres: build + testy, zero podpisywania, zero sekretów.
> Status: zatwierdzony przez użytkownika przed implementacją.

## Cel

Po pushu/PR do `develop` lub `release` GitHub uruchamia testy pakietów SPM;
czerwony wynik widoczny natychmiast (badge + status na PR). Spełnia wymóg
„pipeline buduje i uruchamia testy".

## Krok 0 — warunek wstępny (WYKONANY przed planem)

- Pełna suita `SharedModels` lokalnie zielona: 38/38 (naprawiony zastany czerwony
  test `SharedPlanCodec` — fixture z `.now` vs pełnosekundowa strategia ISO 8601
  kodeka; fix wyłącznie w pliku testowym).

## Kroki automatyczne (wykonuje agent po zatwierdzeniu)

1. Utworzenie `.github/workflows/ci.yml`:
   - trigger: `push` i `pull_request` na gałęzie `develop`, `release`
   - `concurrency` z `cancel-in-progress` (kolejny push ubija poprzedni run — oszczędza minuty)
   - job `spm-tests`: `runs-on: macos-26` (PIN — nie `macos-latest`; obraz ma Xcode 26.0.1–26.6, domyślnie 26.6)
   - matrix po pakietach z testami: dziś `SharedModels` (konstrukcja gotowa na dołożenie `PersonalRecords`)
   - cache SPM: `actions/cache@v4`, path `<pakiet>/.build`, klucz `spm-<pakiet>-${{ hashFiles('<pakiet>/Package.resolved', '<pakiet>/Package.swift') }}`
   - krok testowy: `swift test --package-path <pakiet>`
2. Badge statusu w `README.md` (jedna linia na górze).

Świadomie POZA planem (zapisane w infrastructure.md): pełny `xcodebuild` aplikacji
(drogi na M1-runnerze; do rozważenia jako osobny job tylko na `release` po
okrzepnięciu pipeline'u), symulatory, podpisywanie, TestFlight.

## Zakres targetów (jawne wykluczenia)

- MVP nie buduje żadnego targetu aplikacji — wyłącznie `swift test` pakietów SPM
  (fundament współdzielony przez wszystkie właściwe targety).
- Przyszły job buildowy (faza 2, tylko `release`): wyłącznie scheme `WorkoutMirrorLive`
  (ewentualnie `WorkoutMirror Watch App` / `GymRoom` — decyzja wtedy).
- Legacy targety `StepTrackerTCA` i `MyFitnessJournal Watch App`: NIGDY w CI —
  przeznaczone do usunięcia; w Actions buduje się jawnie wskazany scheme, więc
  nie ma mechanizmu, który wciągnąłby je przypadkiem.

## Bramki ręczne (użytkownik)

1. Commit + push workflow na bieżącym branchu lekcji (`dev/10xDev/lesson1.5`) —
   uwaga: workflow z triggerem na `develop`/`release` zadziała W PEŁNI dopiero,
   gdy plik dotrze na te gałęzie; na branchu lekcji zadziała trigger `pull_request`,
   jeśli otworzysz PR do develop.
2. (Opcjonalnie, po zielonym pierwszym runie) Settings → Branches → required
   status check `spm-tests` dla PR do `develop`.

## Weryfikacja

1. `gh run watch` po pushu — oczekiwane: job `spm-tests (SharedModels)` zielony, ~2–4 min (pierwszy run bez cache ~4–6 min).
2. `gh run view <id> --log-failed` przy czerwonym.
3. Kontrola zużycia: Settings → Billing (oczekiwane ~30–60 min/mies. przy obecnym wolumenie pushów).

## Rollback

Workflow to plik w repo — `git revert` przywraca poprzedni stan; czerwony run
niczego nie psuje poza statusem. Wyłączenie awaryjne: zakładka Actions → Disable workflow.

## Koszt (szacunek)

Test job: ~3 min × mnożnik macOS ×10 = 30 min budżetu na run; ~10–15 runów/mies.
przy triggerze develop+release = 300–450 min budżetu… (⚠ patrz mitygacja) —
dlatego `concurrency: cancel-in-progress` + brak buildu aplikacji w MVP;
realne zużycie przy 2–4-minutowych testach: mieści się w 2000 min planu Free.
