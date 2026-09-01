# Usuwanie wpisu PR (S-05) — krótki plan

> Pełny plan: `context/changes/delete-entry-recompute/plan.md`

## Co i dlaczego

Usuwanie wpisu z historii ruchu z potwierdzeniem (FR-006) — PR i liczniki cofają się same (czysta funkcja + `@FetchAll`). Plus test TestStore przepływu edytora — ostatni brakujący wymóg certyfikacji.

## Kluczowe podjęte decyzje

| Decyzja | Wybór | Dlaczego | Źródło |
| --- | --- | --- | --- |
| Gest usuwania | Long-press (contextMenu) + confirmationDialog | `swipeActions` działa tylko w List — swipe wymagałby przebudowy kart (guardrail wizualny); potwierdzenie = sedno FR-006 | Plan (user) |
| Przeliczenie PR | Zero kodu — własność architektury S-02 | `@FetchAll` + PRResolver: usunięcie w bazie samo cofa PR | Plan |
| Test przepływu | TestStore w NOWYM targecie WorkoutMirrorLiveTests (Xcode UI, krok ręczny) | App target nie ma testów; pbxproj tylko przez Xcode UI | Plan |
| Równoległość | Implementacja przez subagenta w izolowanym worktree | Ćwiczenie lekcji 2.5; S-06 idzie równolegle w głównym drzewie | Plan (user) |

## Fazy w skrócie

| Faza | Co dostarcza | Kluczowe ryzyko |
| --- | --- | --- |
| 1. Delete end-to-end | klient.delete + menu + dialog | styk z S-06 na plikach PRMovementDetail (możliwy drobny konflikt przy merge) |
| 2. Test TestStore | pierwszy test przepływu reducera | krok ręczny: user tworzy target testowy w Xcode |

**Poza zakresem:** swipe, undo/soft-delete, edycja wpisu, zmiany S-06.
