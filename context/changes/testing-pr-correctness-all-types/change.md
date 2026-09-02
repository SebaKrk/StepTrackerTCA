---
change_id: testing-pr-correctness-all-types
title: Poprawność PR wszystkich typów — testy jako specyfikacja przed S-03/S-04
status: implementing
created: 2026-09-02
updated: 2026-09-02
archived_at: null
---

## Notes

Open a change folder for rollout Phase 2 of context/foundation/test-plan.md: "Poprawność PR wszystkich typów". Risks covered: #1 (użytkownik dobiera ciężar na sali na podstawie błędnie wyznaczonego PR — zły kierunek dla czasu, AMRAP nieleksykograficznie, scaled bije Rx, źle rozstrzygnięty remis). Test types planned: unit (czysta funkcja), pisane test-first PRZED implementacją S-03/S-04 (materiał lekcji 3.2 — /10x-tdd). Risk response intent: #1 — udowodnić, że dla każdego typu wyniku gorszy nowy wynik NIE zostaje PR-em, lepszy zostaje; scaled nigdy nie bije Rx; remis rozstrzyga nowsza data. Wyrocznia ze źródeł (PRD FR-007, US-02, Business Logic Changes), NIE z implementacji resolvera — challenge: "istniejące testy resolvera pokrywają też przyszłe typy z S-03/S-04". Anti-pattern: problem wyroczni (oczekiwane wartości ściągnięte z implementacji), happy-path only. After creating the folder, follow the downstream continuation rule.
