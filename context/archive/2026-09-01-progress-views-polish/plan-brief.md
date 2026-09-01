# Wykres postępu i dopełnienie widoków (S-06) — krótki plan

> Pełny plan: `context/changes/progress-views-polish/plan.md`

## Co i dlaczego

Domknięcie FR-009 na szczególe ruchu: wykres postępu od 2+ wpisów (oś odwrócona dla czasu) i krotność masy ciała przy PR ciężarowym. Historia/ikony/daty względne już istnieją z S-02.

## Kluczowe podjęte decyzje

| Decyzja | Wybór | Dlaczego | Źródło |
| --- | --- | --- | --- |
| Dostępność (otwarte pytanie roadmapy) | Świadoma rezygnacja w MVP | Termin 07.09; systemowych zachowań nie psujemy; temat wraca po MVP | Plan (user) |
| Wykres | Swift Charts, LineMark+PointMark, computed `chartPoints` w State | Wzorce w repo (ExerciseDetail, HRMinuteRangeChart); zero nowego stanu | Plan |
| Oś dla czasu | Odwrócona (lepszy=krótszy czas wyżej) | FR-009 wprost | Badania (PRD) |
| Skalar AMRAP | rounds + extraReps/100 | Monotoniczny względem porównania leksykograficznego | Plan |
| Równoległość | Ja w głównym drzewie; S-05 u subagenta w worktree | Ćwiczenie lekcji 2.5 | Plan (user) |

## Fazy w skrócie

| Faza | Co dostarcza | Kluczowe ryzyko |
| --- | --- | --- |
| 1. Karta Progress | wykres od 2+ wpisów | styk z S-05 na plikach PRMovementDetail (możliwy drobny konflikt przy merge) |
| 2. Krotność BW | „×N.NN BW" na hero | brak (trywialne) |

**Poza zakresem:** dostępność, zmiany S-05, wykres poza szczegółem, porównania Rx/scaled (S-04), zmiana skinu.
