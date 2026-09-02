<!-- IMPL-REVIEW-REPORT -->
# Przegląd implementacji: Poprawność PR wszystkich typów (test-plan §3 Faza 2)

- **Plan**: context/changes/testing-pr-correctness-all-types/plan.md
- **Zakres**: Fazy 1–3 z 3 (pełny plan)
- **Data**: 2026-09-02
- **Werdykt**: ZAAKCEPTOWANY
- **Ustalenia**: 0 krytycznych, 2 ostrzeżenia, 4 obserwacje

## Werdykty

| Wymiar | Werdykt |
|-----------|---------|
| Zgodność z planem | PASS (8/9 MATCH; 1 uzasadniony DRIFT na korzyść pokrycia) |
| Dyscyplina zakresu | PASS (zero plików spoza zakresu; bariery „Czego NIE robimy" czyste) |
| Bezpieczeństwo i jakość | WARNING (F1) |
| Architektura | PASS (publiczne sygnatury bez zmian) |
| Spójność wzorców | PASS (Package.swift, testy, withKnownIssue, komunikaty — wzorce repo) |
| Kryteria sukcesu | PASS (suita 22/22 + 2 known issues; red run udokumentowany; build potwierdzony) |

## Ustalenia

### F1 — Partycja D4 jest globalna, nie per-koszyk Rx/scaled — brzeg nieprzetestowany

- **Ważność**: ⚠️ OSTRZEŻENIE
- **Wpływ**: 🔎 ŚREDNI — prawdziwy kompromis; zatrzymaj się, aby to przemyśleć
- **Wymiar**: Bezpieczeństwo i jakość
- **Lokalizacja**: SharedModels/Sources/SharedModels/SharedModels/PRCatalog/PRResolver.swift:36-43
- **Szczegóły**: Benchmark z wpisem matching-scaled + mismatched-Rx → `ranked = matching` → `bestRx == nil`, mimo że wpis Rx istnieje. Zachowanie obronialne (bogus nie powinien być hero), ale: komentarz „nothing is silently hidden" nieprecyzyjny (slot Rx pustoszeje), asymetria z fallbackiem mismatched-only nieprzetestowana żadnym z 9 testów.
- **Poprawka**: test charakteryzujący (matching-scaled + mismatched-Rx → `bestRx == nil`) + doprecyzowanie komentarza D4 (fallback całościowy, nie per-koszyk); logika bez zmian — decyzja doprecyzowuje D4.
  - Siła: domyka jedyny niechroniony brzeg partycji; zero zmian zachowania.
  - Kompromis: żaden istotny.
  - Pewność: HIGH — zachowanie zweryfikowane w kodzie przez recenzenta.
  - Martwy punkt: mismatched nie może dziś powstać przez UI (editor tylko weight) — wektor to korupcja danych/przyszłe migracje.
- **Decyzja**: FIXED (test mismatchedRxVacatesRxSlot + doprecyzowany komentarz D4)

### F2 — Doc `PREntry.isRx` nieaktualny po decyzji D3

- **Ważność**: ⚠️ OSTRZEŻENIE
- **Wpływ**: 🏃 NISKI — szybka decyzja; poprawka jest oczywista i wąsko zakrojona
- **Wymiar**: Zgodność z planem (dług dokumentacyjny decyzji wyroczni)
- **Lokalizacja**: SharedModels/Sources/SharedModels/SharedModels/PRCatalog/PREntry.swift:95
- **Szczegóły**: Doc mówi „nil when the movement does not support Rx/scaled", a po D3 nil na benchmarku to legalny stan rankowany jako scaled — myląca dokumentacja przy implementacji S-04 (picker Rx/scaled).
- **Poprawka**: 1 linia doc: „nil = undeclared — ranked as scaled on benchmarks (D3); always nil where unsupported."
- **Decyzja**: FIXED (doc isRx zaktualizowany o D3)

### F3 — Wykres detalu pokazuje wpisy mismatched na złej osi

- **Ważność**: 💬 OBSERWACJA
- **Wpływ**: 🏃 NISKI
- **Wymiar**: Bezpieczeństwo i jakość
- **Lokalizacja**: WorkoutMirrorLive/.../PRMovementDetailFeature+State.swift:83-87 (chartPoints z pełnego entries)
- **Szczegóły**: summary wyklucza mismatched z rankingu, ale chartPoints nie — wpis `.time` na ruchu weight wylądowałby na osi kilogramów. Historia celowo pokazuje wszystko (kasowalność FR-006) — OK; wykres to niespójność. Te same mitygacje co F1.
- **Poprawka**: odnotować jako kandydat przy S-03 (filtr chartPoints po scoreType ruchu).
- **Decyzja**: SKIPPED — odnotowane jako kandydat przy S-03 (filtr chartPoints)

### F4 — Telemetria D4 strzela przy każdym przeliczeniu summary; bodyWeightMultiple woła summary drugi raz

- **Ważność**: 💬 OBSERWACJA
- **Wpływ**: 🏃 NISKI
- **Wymiar**: Bezpieczeństwo i jakość
- **Lokalizacja**: PRResolver.swift:40-42; PRMovementDetailFeature+State.swift:52-70
- **Szczegóły**: reportIssue per mismatched per render (DEBUG); w RELEASE no-op; message w @autoclosure. Realny spam tylko gdyby mismatched istniał. Zostawić; dedupe rozważyć, gdy S-03 uczyni takie wpisy możliwymi.
- **Decyzja**: SKIPPED

### F5 — Plan mówił „~7 testów", jest 6; opcjonalny createdAt-tie na typie nie-weight

- **Ważność**: 💬 OBSERWACJA
- **Wpływ**: 🏃 NISKI
- **Wymiar**: Zgodność z planem
- **Lokalizacja**: PRResolverTests.swift (Oracle edges)
- **Szczegóły**: Wyliczenie (a)–(e) sumuje się do 6; pokrycie luk #1–#5 kompletne; ścieżka createdAt w isBetter jest type-agnostic, więc jeden test weight spełnia „jeden test per właściwość". DRIFT F2.1b (mismatchedOnlyStillSurfaces zamiast redundantnego testu) — uzasadniony, chroni jedyną nietestowaną gałąź fallbacku.
- **Poprawka**: nic nie robić (opcjonalnie 1 test createdAt-tie nie-weight).
- **Decyzja**: SKIPPED

### F6 — Nietranzytywność porównań w heterogenicznej historii mismatched-only

- **Ważność**: 💬 OBSERWACJA
- **Wpływ**: 🏃 NISKI
- **Wymiar**: Bezpieczeństwo i jakość
- **Lokalizacja**: PRResolver.swift:84-101
- **Szczegóły**: Dwa RÓŻNE złe typy na jednym ruchu → orderedSame między parami mieszanymi → wynik reduce zależny od kolejności; lista i detal mogłyby teoretycznie pokazać różne „best". Komentarz uczciwie adresuje („good enough"). Czysto teoretyczne.
- **Poprawka**: zostawić.
- **Decyzja**: SKIPPED
