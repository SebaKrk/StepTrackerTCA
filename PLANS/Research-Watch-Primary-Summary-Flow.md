---
Autor: Sebastian Ściuba
Data: 2026-06-11
Status: Research / decyzja architektoniczna do podjęcia
Typ: Research note — nie plan implementacyjny
Powiązane memorie:
  - project_workout_summary_bug.md (race condition fix w HealthHub)
  - project_workout_sync_watchprimary_bug.md (IOS-00091 fix)
  - project_workout_refactor_roadmap.md
  - reference_wwdc25_hybrid_workout_terminology.md
  - reference_workout_ios26_architecture.md
---

# Watch-primary workout summary — research i decyzja kierunkowa

## 1. Problem (startowe pytanie)

Obecna implementacja podsumowania treningu na iPhonie po zakończeniu sesji na Watchu **trwa długo** (kilkanaście sekund do minut) i **czasem się nie udaje**. Ostatnio: czy iOS 26 daje nowe narzędzia, których nie używamy?

## 2. Co Apple faktycznie mówi (WWDC25 #322 + WWDC23 #10023 + docs)

W trybie watch-primary mirroring:

- **Watch jest jedynym właścicielem `HKLiveWorkoutBuilder`.** iPhone w mirrored session **nie buduje** swojego `HKWorkout`.
- Po `session.stopActivity` na Watchu:
  1. `builder.endCollection(at:)`
  2. `let finished = try await builder.finishWorkout()` → `HKWorkout` zapisany **lokalnie w HealthKit store Watcha**
  3. `session.end()`
- iPhone dostaje workout dopiero gdy **HealthKit sync** (przez iCloud/system) przeniesie go do telefonowego store'a.
- Apple cytuje wprost: *"Once the phone is unlocked, HealthKit will save the workout and make it available to your app via the Health Store."* — czyli **odblokowanie telefonu** jest warunkiem.
- **Brak SLA**, brak push eventu „workout finished on companion", brak gwarancji niezawodności.

iOS 26 dodaje:
- Live metric mirror → iPhone *w trakcie* treningu (nie pomaga przy summary)
- Streamlined workout creation na iPhonie (sync custom workouts → Watch)
- Crash recovery (Watch-side)
- Workout Buddy (Apple-only)

**Czego iOS 26 NIE dodaje:** żadnego nowego API do natychmiastowego dostarczenia końcowego `HKWorkout` z Watcha na iPhone. Cały mechanizm pozostaje "Watch zapisuje → HealthKit sync resztę".

Bonus: znany bug `sendToRemoteWorkoutSession` ~5% przypadków nigdy nie zwraca (forum thread 769355, watchOS 10/11, iOS 17/18, brak oficjalnej odpowiedzi Apple) — więc nawet jeśli próbowalibyśmy obejść sync wysyłając summary przez ten kanał, to nie jest niezawodne.

## 3. Root cause dlaczego "trwa długo i nie zawsze się udaje"

HealthKit cross-device sync to **asynchroniczny, opóźniony, warunkowy** mechanizm zależny od:
- odblokowanego iPhone'a
- iCloud reachability
- dostępnego czasu w tle dla obu device'ów
- wybudzenia Watcha do dokończenia push

To nie jest bug naszej implementacji — to jest właściwość platformy. Próby ścigania się z tym sync to walka z wiatrakami i właśnie tam żyją race conditions (workout_summary_bug, watchPrimary race / IOS-00091).

## 4. Propozycja kierunku: rozdzielić "result" od "review"

Zamiast walczyć o iPhone-side instant summary, dopasować architekturę do realiów platformy:

| Pojęcie | Primary device | Gotowe kiedy | Źródło danych |
|---|---|---|---|
| **Workout result** (HealthKit fakty: czas, HR avg, dystans, kalorie, segmenty) | Watch | T+0s od `finishWorkout()` | `HKWorkout` lokalnie na Watchu |
| **Workout review** (user input: notatki, RPE, mood, tagi, zdjęcia, edycja typu, share) | iPhone | gdy user otworzy app | `HKAnchoredObjectQuery` + lokalna kolejka "do review" |

iPhone czeka na HealthKit sync **w tle, bez stresu UX-owego**. Kiedy `HKWorkout` przyjedzie:
- Lokalna kolejka "pending review" dostaje nowy element
- App pokazuje go z aktywnym prompt'em: *"Add notes? Rate this workout?"*
- Review staje się **aktywną intencją**, a nie pasywnym ekranem "ładowania"

Apple Fitness sam działa w ten sposób — to jest sanctioned UX pattern.

## 5. Tradeoffs

**Plusy:**
- Eliminuje całą kategorię race conditions (warstwa, którą łatamy w `project_workout_summary_bug.md` i IOS-00091 staje się niepotrzebna)
- Zgodne z modelem Apple — flow Watch-primary jest naturalnie wspierany
- Upraszcza `TrainingManager` (jego odpowiedzialność kurczy się do *live* metryk)
- Otwiera miejsce na nowego aktora typu `WorkoutReviewClient` (czyste SRP, zgodne z S z SOLID + Client/Service wzorcem z CLAUDE.md)
- Zerowy koszt dla user behavior gdzie telefon wraca do ręki 5–60 min po treningu (typowy gym)

**Minusy / koszt:**
- Tracimy „end → instant phone summary" jako wow-moment (jeśli to był UX center-piece)
- Wymagana zmiana mental model usera: telefon to **review**, nie **passive viewer**
- Migracja: trzeba przemyśleć co zrobić z istniejącymi screenami które dziś próbują pokazywać świeże summary

**Mitigation dla minusów:**
- Live Activity z komunikatem „Trening zapisany, summary za chwilę" — daje closure bez czekania
- Shadow summary (akumulacja `didReceiveDataFromRemoteWorkoutSession` w trakcie) jako fallback gdyby sync nie dotarł w X sekund — defense in depth tylko dla edge case, nie jako main flow

## 6. Otwarte pytania (do decyzji przed implementacją)

1. **Czy realny user behavior w naszej app to "od razu sięgam po telefon" czy "patrzę na Watch i wracam później"?**
   - Jeśli to drugie → przejście jest czysty win
   - Jeśli pierwsze → trzeba świadomie zaprojektować zastępczy UX (Live Activity? shadow summary?)
2. **Co Watch ma pokazać po zakończeniu — własny summary screen czy deeplink do Apple’owego built-in?**
   - Własny = pełna kontrola UX, więcej do utrzymania
   - Apple built-in = minimal effort, mniej brandingu
3. **Jak iPhone wykrywa "nowy nieobsłużony workout do review"?**
   - Wstępna odpowiedź: `HKAnchoredObjectQuery` na `HKWorkoutType` + persisted anchor (np. AppStorage) + lokalna kolejka pending review
   - To staje się sercem iPhone app, nie listening na live metrics

## 7. Co to zmienia w istniejących memoriach / kodzie

Jeśli wybierzemy ten kierunek, do przeglądu / aktualizacji:

- `project_workout_summary_bug.md` — fix dalej działa, ale traci znaczenie (problem znika z głównego flow)
- `project_workout_sync_watchprimary_bug.md` (IOS-00091 4 warstwy defense in depth) — j.w., warstwy stają się fallback, nie main path
- `TrainingManager` (per `project_workoutmirror_managers.md`) — odpowiedzialność kurczy się do live metrics
- `project_workout_refactor_roadmap.md` (Hybrid dual-mode roadmap) — ten kierunek jest komplementarny, nie konkurencyjny, ale warto wpiąć w którąś z faz

## 8. Status / next step

**Decyzja kierunkowa jeszcze NIE podjęta.** Ta notatka istnieje żeby do niej wrócić.

Przed implementacją należałoby:
1. Odpowiedzieć na 3 pytania z sekcji 6
2. Zdecydować czy to oddzielny ticket, czy część `project_workout_refactor_roadmap.md`
3. Jeśli ticket → utworzyć IOS-NNNNN, sub-projekty, plan w `PLANS/`

## 9. Źródła Apple

- WWDC25 #322 — Track workouts with HealthKit on iOS and iPadOS: https://developer.apple.com/videos/play/wwdc2025/322/
- WWDC23 #10023 — Build a multi-device workout app: https://developer.apple.com/videos/play/wwdc2023/10023/
- HKWorkoutSession docs: https://developer.apple.com/documentation/healthkit/hkworkoutsession
- startMirroringToCompanionDevice: https://developer.apple.com/documentation/healthkit/hkworkoutsession/startmirroringtocompaniondevice(completion:)
- workoutSessionMirroringStartHandler: https://developer.apple.com/documentation/healthkit/hkhealthstore/workoutsessionmirroringstarthand
- HKLiveWorkoutBuilder.finishWorkout: https://developer.apple.com/documentation/healthkit/hkworkoutbuilder/finishworkout(completion:)
- Forum thread 769355 — sendToRemoteWorkoutSession 5% failure: https://developer.apple.com/forums/thread/769355
- Build a workout app for Apple Watch (tutorial): https://developer.apple.com/documentation/HealthKit/build-a-workout-app-for-apple-watch
- Nonstrict: HKWorkoutSession remote delegate not setup error: https://nonstrict.eu/blog/2024/hkworkoutsession-remote-delegate-not-setup-error/
