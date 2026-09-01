---
change_id: record-entry-current-pr
title: Tablica PR — zapis wpisu z metadanymi i wyznaczanie aktualnego PR
status: implemented
created: 2026-08-31
updated: 2026-09-01
archived_at: null
---

## Notes

S-02 z context/foundation/roadmap.md (gwiazda przewodnia, US-01): użytkownik zapisuje wynik ciężarowy z pełnymi metadanymi (data domyślnie dziś, Rx/scaled gdzie wspierane, sprzęt, kontekst fresh/inWod/competition, RPE, notatka; masa ciała dopisana automatycznie jako snapshot z PersonalDataClient) i natychmiast widzi zaktualizowany PR na szczególe ruchu oraz rosnący licznik kategorii. Wpis trwały (nowe tabele w migracji v12, append-only), PR wyliczany czystą funkcją z historii (bez zdenormalizowanej wartości; kierunek "więcej=lepiej" dla ciężaru, remis→nowsza data) — Z TESTAMI czystej funkcji (jawne kryterium sukcesu PRD i wymóg certyfikacji). FR-004, FR-005 (kontrolka ciężaru), FR-007 rdzeń, FR-009 (szczegół+licznik), FR-012. Przed planem: research zewnętrzny — changelog sqlite-data 1.6.6→1.11.0 (follow-up z health-check przed pierwszą nową migracją).
