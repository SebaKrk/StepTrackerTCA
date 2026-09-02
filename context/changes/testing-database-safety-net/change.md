---
change_id: testing-database-safety-net
title: Siatka bezpieczeństwa bazy — migrator z danymi i round-trip zapisów
status: implementing
created: 2026-09-02
updated: 2026-09-02
archived_at: null
---

## Notes

Open a change folder for rollout Phase 1 of context/foundation/test-plan.md: "Siatka bezpieczeństwa bazy". Risks covered: #2 (migracja bazy niszczy dane użytkownika — logi serii, ręczne wpisy PR bez ścieżki odzysku), #3 (wpis ginie cicho między formularzem a bazą — zapis udaje sukces, odczyt zwraca inne wartości). Test types planned: integration in-memory w pakiecie bazy. Risk response intent: #2 — migrator przechodzi v1→vN na bazie Z DANYMI poprzedniej wersji i dane przeżywają (nie tylko pusta baza); #3 — round-trip: wpis zapisany klientem wraca z odczytu z identycznymi wartościami, a niepełne/nieznane dane nie znikają cicho. After creating the folder, follow the downstream continuation rule.
