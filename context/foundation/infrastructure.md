---
project: MyFitnessJournal (StepTrackerTCA)
researched_at: 2026-08-30
recommended_platform: GitHub Actions
runner_up: Codemagic
context_type: mvp
tech_stack:
  language: Swift 6
  framework: SwiftUI + TCA (Xcode 26, 5 lokalnych pakietów SPM)
  runtime: iOS 26 / watchOS 26 (deploy aplikacji: TestFlight/App Store — poza zakresem tej decyzji)
---

> Adaptacja brownfield/iOS: „platforma wdrożeniowa" oznacza tu **platformę CI/CD**.
> Deploy aplikacji jest przesądzony (TestFlight/App Store przez konto release);
> otwartą decyzją infrastrukturalną był wybór CI. Zakres z wywiadu: **build + testy,
> bez podpisywania i publikacji** (wydania pozostają ręczne z Xcode).

## Recommendation

**CI na GitHub Actions.**

Jedyna platforma z kompletem cech agent-friendly przy zerowym koszcie wejścia: konfiguracja jako YAML w repo (wersjonowana), pełny cykl trigger→status→logi z terminala (`gh run list/view --log-failed/watch`), dokumentacja w markdown, obraz `macos-26` z preinstalowanym Xcode 26 (domyślnie 26.6) — a repo już żyje na GitHubie, więc zero nowych kont i sekretów. Decyzję przesądziły: wywiad (zakres build+testy → podpisywanie niepotrzebne; koszt priorytetem → darmowe ~200 min macOS/mies. wystarcza dla testów SPM) oraz twardy filtr eliminujący głównego rywala (Xcode Cloud wymaga płatnego Apple Developer Program, którego właściciel nie ma — wydania idą przez cudze konto release).

## Platform Comparison

Kryteria agent-friendly (✅ pass / ⚠️ partial / ❌ fail); dane z równoległego badania web z 2026-08-30 (linki-dowody w raportach badawczych; wszystkie funkcje GA, chyba że oznaczono):

| Platforma | CLI-first | Managed | Docs dla agenta | Stabilne API uruchomień | MCP/integracja | Darmowy budżet macOS |
|---|---|---|---|---|---|---|
| **GitHub Actions** | ✅ `gh run` pełny cykl | ✅ | ✅ markdown (github/docs, runner-images) | ✅ YAML w repo | ✅ GitHub MCP | ~200 min/mies. (M1, mnożnik ×10), $0.062/min po |
| Xcode Cloud | ⚠️ brak CLI (ASC API; logi jako artefakt) | ✅ | ❌ strony JS | ⚠️ konfiguracja w panelu ASC — niewersjonowalna | ❌ | 25 h/mies. — ale wymaga płatnego ADP ($99/rok) |
| Codemagic | ⚠️ REST bez endpointu logów, brak CLI zdalnego | ✅ | ⚠️ | ✅ codemagic.yaml w repo | ❌ | 500 min/mies. (Mac mini M2) |
| Bitrise | ⚠️ CLI tylko lokalne; REST logi limitowane | ✅ | ⚠️ | ✅ bitrise.yml w repo | ❌ | ~150 min/mies. (300 kredytów); potem od $89/mies. |
| CircleCI | ✅ nowy `circleci` CLI z logami `--json` | ✅ | ⚠️ | ✅ | ❌ | ~150 min/mies. (M4 Pro, 200 kredytów/min) |

Twarde filtry: (1) **Xcode Cloud — odpada**: wymaga członkostwa ADP, którego brak; dodatkowo nie buduje standalone pakietów SPM (testy tylko przez schemat aplikacji-hosta) i trzyma konfigurację poza repo. (2) Wszystkie pozostałe wspierają Xcode 26 — brak eliminacji po runtime.

Wagi z wywiadu: koszt > DX; brak doświadczenia CI (premia za prostotę i brak nowego dostawcy); trigger: push/PR do develop+release.

### Shortlisted Platforms

#### 1. GitHub Actions (Recommended)

Komplet kryteriów agentowych + kolokacja z repo. `macos-26` (GA) ma Xcode 26.0.1–26.6 preinstalowane; `gh` CLI daje agentowi samodzielny cykl diagnostyczny; docs i README obrazów w markdown. Budżet: testy pakietów SPM (2–4 min/run) mieszczą się w 200 min z dużym zapasem; pełny build aplikacji rezerwujemy na rzadsze wyzwalacze (mitygacja niżej).

#### 2. Codemagic

Największy realny darmowy budżet bez ADP (500 min/mies. na M2 — szybszym niż M1 GitHuba), `codemagic.yaml` w repo, obrazy Xcode 26 w ~2 dni po releasach Apple. Przegrywa dostępem agentowym: brak CLI do zdalnego triggera, brak endpointu logów (REST + artefakty) — diagnostyka z sesji wymaga klikania. Platforma Flutter-first (czysty Swift działa, ale przykłady/tooling celują w Fluttera). Sensowny plan B, gdyby budżet minut GitHuba realnie bolał.

#### 3. CircleCI

Technicznie świetne (świeże obrazy Xcode, najlepsze obok GH CLI: `circleci run watch`, `job output get --json`), ale ~150 min macOS/mies. na darmowym planie to za mało na regularne CI, a przewag nad GitHubem brak — przy repo na GitHubie to dodatkowy dostawca bez zysku.

(Bitrise poza listą: najsłabszy darmowy budżet i skok od razu na $89/mies.)

## Anti-Bias Cross-Check: GitHub Actions

### Devil's Advocate — Weaknesses

1. **Mnożnik ×10 zjada budżet cicho** — pełny `xcodebuild` aplikacji (5 pakietów, TCA) na standardowym runnerze to 15–25 min realnego czasu; 8–10 takich buildów wyczerpuje miesięczny budżet, potem $0.062/min albo joby odrzucane z braku minut.
2. **Standardowy runner jest słaby**: M1, 3 vCPU, 7 GB RAM — build trwający lokalnie 3 min potrwa ~5×; pętla feedbacku może rozczarować przy pierwszym kontakcie z CI.
3. **Dryf toolchaina**: domyślny Xcode obrazu (26.6 na `macos-26`) może być nowszy niż lokalny — subtelne różnice strict concurrency między minorami Swifta ujawnią się najpierw w CI.
4. **Cache SPM źle skonfigurowany = cichy pożeracz minut** — bez klucza z `Package.resolved` każdy run resolwuje i buduje TCA od zera (+5–10 min/run).

### Pre-Mortem — How This Could Fail

Zaczęło się dobrze: `swift test` pakietów, trzy minuty, zielona lampka. Po miesiącu dołożyliśmy pełny build aplikacji na każdy push do developa — skoro działa, czemu nie. W grudniu przyszedł sprint wydaniowy: trzydzieści pushów w dwa tygodnie, budżet minut wyczerpany dziesiątego, kolejne joby wiszą albo failują z braku środków. „Wyłączę CI na chwilę" zamieniło się w na stałe. Równolegle alias `macos-latest` awansował na macos-27 z betą Xcode 27 — workflow bez pinu wersji świecił czerwono od tygodni i nikt nie patrzył, bo „CI i tak nie działa". Badge w README kłamał, certyfikat wisiał na screenshotach z sierpnia. Sekcja post-mortem wskazała trzy przyczyny: zakres pipeline'u rósł bez decyzji (build powinien biec tylko na release), obraz i Xcode nie były przypięte, a zużycia minut nikt nie zerkał nawet raz w miesiącu. Żadna z przyczyn nie była techniczna — wszystkie były dyscyplinarne, czyli najtańsze do uniknięcia i najłatwiejsze do zignorowania.

### Unknown Unknowns

- `macos-latest` to **ruchomy alias** — dziś = macos-26; bez jawnego `runs-on: macos-26` pewnego dnia dostaniesz nowy major z betą Xcode.
- Minuty rozliczane są **z zaokrągleniem w górę do pełnej minuty per job** — rozbicie pipeline'u na wiele drobnych jobów marnuje budżet; lepiej mniej, dłuższych jobów.
- Darmowe konto ma limit równoległości jobów macOS — dwa szybkie pushe z rzędu = drugi czeka w kolejce (nie błąd, ale zaskakuje).
- Fork PR-y nie dostają sekretów (dziś nieistotne — pipeline nie ma żadnych sekretów; stanie się istotne przy ewentualnej automatyzacji TestFlight).
- Na `macos-15` domyślny Xcode to **16.4** mimo zainstalowanych 26.x — mylące; na `macos-26` domyślny jest właściwy (26.6).

## Operational Story

- **Preview deploys**: n/d (CI bez deploymentu). Odpowiednik: status checks na PR — wynik `swift test`/builda widoczny w PR zanim zmergujesz.
- **Secrets**: pipeline w zakresie MVP nie używa ŻADNYCH sekretów (build bez podpisywania) — zero powierzchni do wycieku. Przyszły TestFlight = certyfikaty w GitHub Secrets (osobna decyzja).
- **Rollback**: workflow to plik w repo — `git revert` przywraca poprzednią wersję pipeline'u; czerwony run nie psuje niczego poza statusem.
- **Approval**: włączenie/zmiana workflow = zwykły commit (user commituje sam, jak wszystko); operacje destrukcyjne nie istnieją w zakresie (brak deploy/secrets). Ewentualne wyłączenie workflow — ręcznie w zakładce Actions.
- **Logs**: agent czyta samodzielnie: `gh run list --workflow=ci.yml`, `gh run view <id> --log-failed`, `gh run watch <id>`; zużycie minut: Settings → Billing (raz w miesiącu, patrz rejestr ryzyka).

## Risk Register

| Risk | Source | Likelihood | Impact | Mitigation |
|---|---|---|---|---|
| Budżet 200 min wyczerpany przez pełne buildy aplikacji | Devil's advocate | M | M | Zakres jobów: `swift test` pakietów na push/PR (2–4 min); pełny build aplikacji tylko na branchach release; miesięczny rzut oka na Billing |
| Dryf `macos-latest` → nowy major z betą Xcode | Unknown unknowns | H (w horyzoncie roku) | M | Pin `runs-on: macos-26` + jawny wybór Xcode (`DEVELOPER_DIR`), aktualizacja świadomą decyzją |
| Cache SPM nieskuteczny — TCA budowane od zera co run | Devil's advocate | M | M | `actions/cache@v4` na `.build` + `~/Library/Caches/org.swift.swiftpm`, klucz z hashem `Package.resolved` |
| Rozjazd toolchaina CI vs lokalny (strict concurrency) | Devil's advocate | L | M | Pin tej samej minor wersji Xcode w CI co lokalnie; bump lokalny i CI w jednym commicie |
| Wolny runner zniechęca do CI (pętla > 5 min) | Pre-mortem | M | L | Minimalny zakres jobu testowego; cache; brak symulatorów w MVP (testy SPM działają na macOS bez symulatora) |
| CI „wyłączone na chwilę" gnije na stałe | Pre-mortem | M | H | Badge w README + required status check na PR do develop (czerwone = widać natychmiast) |

## Getting Started

Konkretne pierwsze kroki (zweryfikowane względem wersji stacku — Xcode 26.x, SPM tools 6.2):

1. Workflow `.github/workflows/ci.yml`: `runs-on: macos-26`, trigger `push`/`pull_request` na `develop` i `release`, job `swift test` w `SharedModels/` (jedyny pakiet z testami dziś; kolejne dołączą ścieżkami).
2. Cache SPM: `actions/cache@v4`, path `SharedModels/.build`, key `spm-${{ hashFiles('SharedModels/Package.resolved', 'SharedModels/Package.swift') }}`.
3. Weryfikacja z terminala: `gh run watch` po pierwszym pushu; `gh run view --log-failed` przy czerwonym.
4. Required status check na PR do develop (Settings → Branches) + badge w README.
5. (Po starcie Tablicy PR) drugi pakiet w matrixie: `PersonalRecords` — ten sam job, ścieżka z matrixy.

## Out of Scope

The following were not evaluated in this research:
- Podpisywanie kodu i automatyzacja TestFlight/App Store (wydania pozostają ręczne z Xcode — świadoma decyzja z health-check)
- Docker/konteneryzacja (nie dotyczy iOS)
- Architektura produkcyjna (multi-region, HA, DR)
