---
change_id: delete-entry-recompute
title: Tablica PR — usuwanie wpisu z automatycznym przeliczeniem PR
status: archived
created: 2026-09-01
updated: 2026-09-01
archived_at: 2026-09-01T20:48:59Z
---

## Notes

S-05 z context/foundation/roadmap.md: użytkownik może usunąć wpis PR (swipe z potwierdzeniem na liście historii szczegółu ruchu), a aktualny PR i liczniki kategorii samoczynnie wracają do poprzedniego stanu (własność czystej funkcji + @FetchAll — zero ręcznego przeliczania). FR-006, FR-007. DODATKOWO w zakresie: test TestStore głównego przepływu (PREntryEditor: save → klient → dismiss, z withDependencies) — domyka wymóg certyfikacji "≥1 test przepływu użytkownika". Ćwiczenie lekcji 2.5: realizowany RÓWNOLEGLE z S-06 (progress-views-polish).
