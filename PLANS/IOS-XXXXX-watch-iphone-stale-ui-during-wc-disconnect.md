---
ticket: IOS-XXXXX (placeholder — wymień gdy założysz ticket)
created: 2026-06-11
incident_date: 2026-06-08
incident_window: 20:31 — 21:30 (workout 1 + workout 2)
author: Sebastian Ściuba
status: investigation done, fixes proposed, not yet implemented
---

# Workout UI staleness podczas WC disconnect (Watch-primary mode)

## Streszczenie

User w trybie `watchPrimary` zostawił iPhone'a (w aucie / szatni) i wybiegł z Watchem na zewnątrz. Po powrocie zobaczył że "iPhone był zamrożony" i przez to **zakończył workout 1 i zaczął workout 2** — myśląc że trening padł. W rzeczywistości HealthKit session na Watchu działał normalnie, ale **iPhone UI w trybie mirror nie miał świeżych danych** (WC reachability flapping przez 15 minut) — z perspektywy usera wyglądało to jak crash appki.

**Główny brak:** iPhone nie komunikuje stanu **out-of-range / stale data** — brak wizualnego sygnału że "Watch dalej nagrywa, łączność WC zerwana, dane czekają na sync".

## Problem (user-facing)

> "Wybiegłem z Watchem ale iPhone'a zostawiłem, [appka] przestała działać, musiałem wyłączyć trening i włączyć od nowa."

Po rekonstrukcji: appka **nie przestała działać** — to user-experience dało wrażenie crashu.

## Evidence z logów (incident 2026-06-08)

### Pliki

Local-only (Downloads):
- `iphone_log_1780943501.txt` — preamble (2 linie)
- `iphone_log_1780943506.txt` — workout 1 (start 20:31:46, end 20:55:41)
- `iphone_log_1780944967.txt` — workout 2 (start 20:56:07, end 21:30:33)
- `watch_log_1780944941.txt` — workout 1 (start 20:31:42, end 20:55:41, **uuid=89423C96-509C-49E3-A4F0-999CBEE63CC6**)
- `watch_log_1780947034.txt` — workout 2 (start 20:56:03, end 21:30:34, **bez UUID** — `WATCH WORKOUT — skipped (saved by safety-net)`)
- `watch_log_1780944781..785.txt` — stare workouty z 2026-06-03/05, przesłane dopiero teraz (queue backlog, patrz Bug pochodny B)

### Timeline workout 1 (24 min)

| Czas | Strona | Wydarzenie |
|---|---|---|
| 20:31:42 | Watch | START activityType 11 (Cross) |
| 20:31:46 | iPhone | mirror started — `mode: watchPrimary` |
| 20:31:58 → 20:40:15 | obie | HR streamuje co ~30s **w obie strony**, oba logi się zgadzają |
| **20:40:29** | iPhone | `WC reachability → false` — user wybiegł poza zasięg |
| 20:40:40 → 20:53:11 | iPhone | **12+ flap'ów true/false WC** (granica zasięgu) |
| 20:40:52 → 20:52:50 | Watch | HR ciągle sampluje (107, 133, 151, 157, **160 bpm**) |
| 20:41:01 → 20:50:00 | iPhone | HR jednak doszedł kilka razy mimo flapowania |
| **20:50:00 → 20:55:40** | iPhone | **5:40 luki bez HR** — WC effektywnie zerwał |
| **20:52:50 → 20:55:39** | Watch | **2:49 luki bez HR — nawet na Watchu** (fizyczny problem z sygnałem czujnika) |
| **20:55:39** | Watch | `[UserAction] Stop long-press confirmed on Watch` |
| 20:55:41 | Watch | `WATCH WORKOUT SAVED uuid=89423C96…` ✅ |
| 20:55:41 | iPhone | `WATCH-INITIATED END` + entering `.saving` |
| 20:55:43 → 20:55:45 | iPhone | WC znów flap, `.workoutSaved` notyfikacja **nie dotarła w 10s** |
| 20:55:51 | iPhone | timeout → fallback polling → workout znaleziony (Twój fix IOS-00091 zadziałał) |
| 20:56:03 | Watch | nowy START — workout 2 |

### Key obserwacje

1. **HealthKit na Watchu działał całe 24 min** — workout zapisał się z UUID `89423C96…`.
2. **Workout 1 zakończony przez usera na Watchu** (`Stop long-press`), nie automatycznie.
3. **Workout 2 (34 min) zakończony przez usera o 21:30:33** — Pause/Resume działa normalnie.
4. **iPhone logger pisał do końca workout 1** (`[MaxHR] computed: 187` o 20:56:03 = praca POST-end). To wyklucza hipotezę **hard freeze / app kill**.
5. **WC reachability klastra flap'ów** podczas okna disconnect — 12+ toggle'ów `true/false` w 15 min, czasem 2 toggle w 1 sekundę. Typowe BLE-roaming bouncing na granicy zasięgu.

## Diagnoza root cause

**Hipoteza A (≈85% pewności): Stale data UI, nie faktyczny freeze**

W trybie `watchPrimary` iPhone renderuje UI na bazie stanu `HKWorkoutSession` mirror (WWDC25 #322 hybrid pattern). Mirror update'y w oknie disconnect przyszły **tylko 2 razy w 15 min** (`mirrored session — state=running` o 20:49:16 i 20:50:47).

Z perspektywy usera:
- HR pokazany **5+ minut temu**
- Licznik czasu albo stoi, albo skacze przy mirror update'ach
- Brak jakiegokolwiek **sygnału UI że to przejściowy disconnect**, a workout dalej trwa

User interpretuje to jako "appka się zawiesiła" i restartuje workout.

**Hipoteza B (≈10% pewności): Main thread blocked w WCSession delegate**

Możliwe że delegate `WCSession` na background thread dispatch-sync'uje na MainActor podczas flap'a, prowadząc do mini-deadlocku UI. Sprzeczne z faktem że logger pisał dalej — logger może żyć off-MainActor.

**Hipoteza C (≈5% pewności): Mirror session zombie state**

`HKWorkoutSession` mirror state inconsistency — workout w istocie się skończył ale UI to ignoruje, albo odwrotnie.

## Co wyklucza evidence

- ❌ App crash/kill — logger pisał do końca
- ❌ HealthKit session abort — Watch normalnie zapisał workout z UUIDem
- ❌ WC totalnie umarło — mirror update'y i reachability toggle'e dochodziły, choć rzadko
- ❌ HR sensor zatrzymał się jako root cause — to **konsekwencja** (przerwa 20:52:50 → 20:55:39 to fizyczny sygnał nadgarstkowy, oddzielny od WC)

## Proponowane rozwiązania (priorytet od najwyższego ROI)

### Fix 1 — Out-of-range indicator na iPhone (HIGH PRIORITY)

**Co:** Banner / pill na ekranie workoutu na iPhonie pokazujący stan łączności.

**Trigger:** `WCSession.isReachable == false` przez > 5 sekund.

**Wygląd:** np. orange pill `"Out of range — Watch still recording"` u góry ekranu, z timestampem ostatniego HR `"Last HR: 23s ago"`.

**Dlaczego:** Eliminuje root cause UX — user nie myśli że "padło", tylko widzi że disconnect jest **przejściowy** i workout trwa na Watchu.

**Lokalizacja w kodzie (do sprawdzenia podczas implementacji):**
- Feature mirror na iPhonie (poszukać w `WorkoutMirrorLive/FeaturesNew/` — feature który subskrybuje `mirroredSession` events)
- Reducer State: dodać `connectionStatus: ConnectionStatus` (enum z `.connected`, `.outOfRange(since: Date)`)
- Effect: subskrypcja `WCSession.delegate.sessionReachabilityDidChange`
- View: dodać banner zgodny z **View Facade** pattern z CLAUDE.md (osobny `private var` na pill, sekcje na dole pliku)

**Estimated effort:** 1 atomowy commit. ~2-3 pliki:
1. Mirror feature reducer (state + action + effect)
2. WCSession delegate / dependency exposure jeśli nie ma
3. View binding pill

**Nie dotykać:** HealthKit session logic, polling fallback, save flow (działają).

### Fix 2 — Heartbeat / stale data warning (MEDIUM PRIORITY)

**Co:** Jeśli `mirroredSession` state nie aktualizuje się przez > 60 sekund → drugi sygnał "Stale data" obok pill z Fix 1.

**Dlaczego:** Out-of-range to jeden sygnał, ale czasami WC pokazuje `isReachable == true` ale **mirror state i tak nie idzie do przodu** (widać w logach: `mirrored session — state=running` o 20:49 i 20:50, potem dopiero END o 20:55). User powinien widzieć że **dane są nieaktualne**.

**Lokalizacja:** ten sam reducer co Fix 1. Timer effect z polling co 5s na "czas od ostatniego mirror update".

**Estimated effort:** 1 atomowy commit, ten sam plik co Fix 1 (rozszerzenie state'u).

### Fix 3 — Crash log fetching workflow (LOW PRIORITY, ale ważne dla potwierdzenia)

**Co:** Procedura odczytu crash logów żeby potwierdzić hipotezę A vs B.

**Kroki:**
1. Następnym razem gdy incident się powtórzy: **Settings → Privacy & Security → Analytics & Improvements → Analytics Data**
2. Szukaj plików `WorkoutMirrorLive-*-jetsam-*.ips` (out-of-memory kill) lub `*-spin-*.ips` (main thread hang)
3. Jeśli są pliki `spin` z 2026-06-08 ~20:40-20:55 → potwierdzenie hipotezy B (main thread blocked)
4. Jeśli brak crash logów w tym oknie → potwierdzenie hipotezy A (stale data, nie freeze)

**Bonus:** Podczas testów terenowych podpiąć iPhone do Mac, otworzyć Console.app, filtrować po `process: WorkoutMirrorLive` — live `os_log` jest **dużo bardziej szczegółowe** niż file logger. Dual write z memory: WorkoutFileLogger + `Logger` — `Logger` idzie do unified logging.

## Pochodne bugi (osobne ticki — nie część tego planu)

### Bug pochodny A — Polling fallback zwraca workout 1 UUID dla workout 2

**Evidence:** `iphone_log_1780944967.txt:77`:
```
[21:30:43] SUMMARY RESULT — workout: found: 89423C96-509C-49E3-A4F0-999CBEE63CC6
```

To UUID workoutu **1**, nie 2. Bo:
- Workout 2 nie zapisał się przez Watch z UUIDem (`WATCH WORKOUT — skipped (saved by safety-net)`, `NOTIFY — .workoutSaved skipped (no UUID, save likely failed)`)
- Polling fallback (część Twojego fix'a IOS-00091) zwraca `mostRecentlySaved` workout — czyli workout 1

**Skutek UX:** Po incidencie user widzi w aplikacji **dane workoutu 1 jako "ostatnia sesja"** zamiast workoutu 2.

**Fix:** Polling powinien filtrować po `startDate >= mySessionStart` (np. `mySessionStart - 30s margin`). Wtedy zwróci nil zamiast workoutu 1 → iPhone wie że trzeba ponowić.

**Lokalizacja:** Reducer / client gdzie zaimplementowana polling fallback logic z IOS-00091. Pamięć: `project_workout_sync_watchprimary_bug.md`.

### Bug pochodny B — transferFile queue 3-5 dniowe opóźnienie

**Evidence:** Logi:
- `watch_log_1780944781.txt` — workout z 2026-06-03 11:44
- `watch_log_1780944782.txt` — workout z 2026-06-03 14:34
- `watch_log_1780944783.txt` — workout z 2026-06-03 20:40
- `watch_log_1780944784.txt` — workout z 2026-06-05 15:57
- `watch_log_1780944785.txt` — workout z 2026-06-03 21:06

Wszystkie z **3-5 dni temu**, przesłane dopiero podczas incidentu z 2026-06-08 ~20:53 (gdy WC zaczął się stabilizować po flapach).

**Skutek:** Mimo fix'u IOS-00085-F (eager WCSession w AppDelegate), `transferFile` queue dalej ma latency w realnym świecie. Pamięć: `project_watchconnectivity_patterns.md` mówi że queue wymaga obustronnej reachability — to się utrzymuje, fix F nie wystarcza.

**Investigation needed:** Czy `transferFile` queue resetuje się po `applicationDidBecomeActive`? Czy jest jakiś `outstandingFileTransfers` poll na app launch?

## Otwarte pytania

1. **Hipoteza A vs B vs C** — bez crash logów nie wiem na pewno. Pierwszy krok przy następnym incidencie: sprawdzić `Analytics Data` (Fix 3).
2. **Czy user kliknął End bo iPhone "wyglądał na zamrożony", czy bo Watch dawał jakiś sygnał?** Z logów wynika że Watch działał normalnie (HR rośnie z 107 → 160 bpm w okresie do 20:52:50). User explicit potwierdził: Watch działał, iPhone był zamrożony — ale nie sprawdzał dokładnie co iPhone pokazywał (tap test, scrollowanie etc). Następnym razem: sprawdzić iPhone przed kliknięciem End.
3. **Czy ten sam scenariusz zachowa się gdy iPhone jest podłączony do Mac przez Console.app?** Test setupu w terenie.
4. **Czy Fix 1 + 2 wymaga zmian w `TrainingManager` czy tylko w mirror feature reducer?** Z memory: `TrainingManager` to single dependency dla real HR. Pewnie reducer subskrybuje `WCSession` osobno, ale do potwierdzenia podczas implementacji.

## Konwencje implementacji (gdy się za to weźmiemy)

Z CLAUDE.md i memory:
- **Każdy fix = osobny atomowy commit**: `IOS-XXXXX-A WC out-of-range indicator — banner + state`, `IOS-XXXXX-B Stale data heartbeat — 60s threshold`
- **TCA conventions** (memory): `@Presents`, `@ViewAction`, **żadnego `@State`** w View — wszystko w Store
- **View Facade** (CLAUDE.md): `body` opisuje strukturę, prywatne propery na dole pliku opisują implementację
- **Button verbose** form
- **Workflow >1 plik:** pokaż PRZED/PO, czekaj na akceptację
- **NIE commituj samodzielnie** — user zawsze sam robi commity
- **User story w podsumowaniu** — po implementacji dodaj sekcję user story (`feedback_user_story_in_change_summary.md`)

## Następne kroki

1. **Najbliższy fizyczny trening na zewnątrz** → spróbuj odtworzyć scenariusz, sprawdź iPhone PRZED kliknięciem End (touch test, scrollowanie, screenshot)
2. **Po incidencie:** sprawdź `Settings → Analytics Data` na iPhonie → wklej do tego planu nazwy plików `*.ips` z okna 20:40-20:55
3. **Konsultacja architektoniczna:** czy Fix 1 ma być w istniejącym mirror feature reducer, czy w osobnym `ConnectionStatusFeature`? Pewnie istniejącym — out-of-range to atrybut workoutu, nie osobna domena.
4. **Założenie ticketu:** wymień placeholder `IOS-XXXXX` w nazwie tego pliku.
5. **Pochodne bugi A i B → osobne ticki** (powołać się na ten plan)
