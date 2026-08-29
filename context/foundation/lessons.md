# Lessons Learned

## Streamy z serwisów wystawiaj jako multicast, nigdy jako stored single-stream

Kontekst: serwisy/managery wystawiające `AsyncStream` konsumowane przez reducery TCA (BLE, HealthKit, peer events)
Problem: `AsyncStream` ma jednego iteratora — view remount lub cancel+restart efektu TCA oznacza drugi `for await`, który dostaje ciszę. Bug IOS-00094-I (2026-06-07): `PeerMirrorService.peerEventsStream` był stored — po zmianie trybu watchPrimary→iPhoneStandalone user nie pojawiał się na iPadzie mimo działającego BLE connect.
Reguła: Stream wystawiany przez serwis = multicast (`[UUID: Continuation]` + `broadcast()` + `onTermination` cleanup). Stored single-stream wyłącznie dla jednego subskrybenta znanego w czasie projektowania. Red flag w review: `private let xxxStream` + `private let xxxContinuation` jako stored properties.
Dotyczy: plan, implement, impl-review

## `session.end()` wywołuj zawsze — poza do/catch, nawet gdy `endCollection()` rzuca

Kontekst: end-flow sesji treningowej HealthKit (obie ścieżki: Watch-primary i iPhone-standalone)
Problem: gdy `endCollection()` rzuci i `session.end()` nie zostanie wywołane, `HKWorkoutSession` zostaje w zombie state i blokuje wystartowanie następnego treningu (code=8 przy próbie równoległej sesji).
Reguła: `session.end()` stoi POZA blokiem do/catch końca kolekcji — wykonuje się bezwarunkowo. Każda zmiana end-flow musi to zachować.
Dotyczy: implement, impl-review

## Nowa migracja bazy w DEBUG kasuje dane na urządzeniu dev — zaplanuj moment

Kontekst: AppDatabase, `Schema.swift`, `migrator.eraseDatabaseOnSchemaChange = true` w DEBUG
Problem: incydent 03.08.2026 — po zmianie schematu na fizycznym urządzeniu dev przepadły wszystkie plany, logi serii, wyniki WOD i effort points (przetrwały tylko treningi w HealthKit; CloudKit sync nie działa — SyncEngine niepodpięty).
Reguła: Plan implementacji dodający migrację MUSI zawierać punkt „moment wdrożenia migracji na urządzeniu dev + ewentualny backup danych". Nie wdrażaj migracji w środku cyklu testów polowych.
Dotyczy: plan, plan-review, implement

## Migracje są append-only — nigdy nie edytuj zarejestrowanej migracji

Kontekst: AppDatabase, `DatabaseMigrator` (migracje v1–v11+)
Problem: migrator śledzi migracje po nazwie — edycja już zarejestrowanej `vN` nie wykona się u nikogo, kto ją już przeszedł; schemat rozjeżdża się cicho między instalacjami.
Reguła: Zmiana schematu = zawsze NOWA migracja `vN+1` dopisana na końcu. Nowa tabela = nowy plik w `Records/` z `@Table` + rejestracja `vN+1`. Przy pierwszej okazji dodaj test „migrator przechodzi v1→vN na pustej bazie in-memory".
Dotyczy: plan, implement, impl-review

## Rozszerzenie wersjonowanego katalogu = bump wersji + golden testy w TYM SAMYM commicie

Kontekst: katalogi z zamrożonymi wynikami w bazie — `ExerciseType.catalogVersion` (re-match), wagi Effort Points (`currentWeightsVersion`), przyszły katalog PR
Problem: dopasowanie/wynik liczy się RAZ i jest zamrożony w bazie; rozszerzenie katalogu bez bumpa wersji naprawia tylko przyszłość — historia zostaje zepsuta na zawsze, a brak golden testu pozwala cichej regresji ponownie zatruć dane.
Reguła: Każde rozszerzenie case'ów/aliasów/wag → w tym samym commicie: bump wersji katalogu + wpisy do golden testów (nazwy z prawdziwych danych verbatim). Wersjonowany re-match naprawia historię.
Dotyczy: plan, implement, impl-review

## Reducer nie używa niekontrolowanych zależności — `Date()`, `UUID()`, `Task.sleep`, singletony

Kontekst: wszystkie reducery TCA
Problem: niekontrolowane zależności czynią logikę nietestowalną i niedeterministyczną; istniejący zły precedens w kodzie ≠ licencja na powielanie.
Reguła: W reducerze wyłącznie `@Dependency(\.date)`, `@Dependency(\.uuid)`, `@Dependency(\.continuousClock)` i wstrzykiwane klienty. Przy edycji reducera przeskanuj go pod kątem `Date()`/`UUID()`/`Task.sleep`/singletonów i zgłoś znaleziska.
Dotyczy: implement, impl-review

## Każda zmiana sesji treningowej musi rozważyć OBIE ścieżki: Watch-primary i iPhone-standalone

Kontekst: Session/end-flow, metryki live, pauzy — architektura dwóch równorzędnych torów
Problem: zmiana testowana tylko na jednym torze psuje drugi w niewidoczny sposób (inne źródło HR, inny właściciel `HKWorkoutSession`, inna droga eventów); historyczne race'y w summary i sync watchPrimary wynikały właśnie z tego.
Reguła: Plan i review każdej zmiany dotykającej sesji wymienia jawnie zachowanie na obu torach (watchPrimary + iPhoneStandalone). Brak sekcji „drugi tor" w planie = plan niekompletny.
Dotyczy: frame, plan, plan-review, impl-review

## Typ HealthKit, który zapisujesz, MUSI być w shareTypes — braki failują cicho

Kontekst: `HealthAuthorizationManager` — osobne zestawy readTypes/shareTypes
Problem: `HKSeriesType.workoutRoute()` był tylko w readTypes — zapisy tras failowały bez żadnego błędu widocznego dla użytkownika (trasa „znikała"); debugowanie trwało dni, bo objaw wyglądał jak bug logiki.
Reguła: Nowy zapis do HealthKit = w tym samym commicie dopisz typ do shareTypes (odczyt → readTypes). W review zmiany HK sprawdź autoryzację jako pierwszą hipotezę „cichego" braku danych.
Dotyczy: implement, impl-review

## Flagi systemowe wymagające capabilities gate'uj sprawdzeniem konfiguracji — inaczej crash assertem

Kontekst: CoreLocation (`allowsBackgroundLocationUpdates`), tryby background w Info.plist
Problem: ustawienie `allowsBackgroundLocationUpdates = true` bez `location` w UIBackgroundModes to nieprzechwytywalny assert ObjC (`CLClientIsBackgroundable`) — crash całej aplikacji na urządzeniu, nie błąd do obsłużenia.
Reguła: Przed ustawieniem flagi wymagającej capability sprawdź w runtime, czy Info.plist ją deklaruje; brak → degradacja funkcji + log, nigdy crash. Wzorzec: `WorkoutRouteRecorder.supportsBackgroundLocation`.
Dotyczy: implement, impl-review

## `WKBackgroundModes` przyjmuje wyłącznie tryby watchOS — `location` należy do `UIBackgroundModes`

Kontekst: Info.plist targetu Watch App, walidacja App Store przy uploadzie
Problem: `location` wpisane do `WKBackgroundModes` przechodzi build i działa lokalnie, ale upload do App Store Connect kończy się „Invalid Info.plist value" — wykryte dopiero przy wydaniu 0.6.
Reguła: Tryby lokalizacyjne background deklaruj w `UIBackgroundModes` (także na watchOS); w `WKBackgroundModes` tylko wartości watchOS (`workout-processing` itd.). Review zmian w plist Watch sprawdza ten podział.
Dotyczy: implement, impl-review

## `@DependencyClient` gubi `Data` w closure — użyj ręcznego structa

Kontekst: klienty TCA z closure przyjmującymi/zwracającymi `Data`
Problem: makro `@DependencyClient` cicho gubi parametr `Data` w wygenerowanym kodzie — klient kompiluje się, ale w runtime dane nie przechodzą.
Reguła: Klient z `Data` w sygnaturze closure = ręczny struct bez makra. W review nowego klienta z `Data` sprawdź, czy nie użyto makra.
Dotyczy: implement, impl-review

## W preview helpers bazy używaj `try!`, nie `try?` — `try?` połyka błąd migracji

Kontekst: SwiftUI previews bootstrapujące SQLiteData
Problem: `try?` przy bootstrapie bazy w preview cicho połyka błąd migracji — preview pokazuje pusty stan i wygląda jak bug UI, a naprawdę schemat się nie podniósł.
Reguła: Preview helpers bazy = `try!` (crash preview natychmiast pokazuje prawdziwą przyczynę). `try?` przy migracjach zakazane wszędzie.
Dotyczy: implement, impl-review

## Wzorce .gitignore kotwicz ukośnikiem — `core.ignorecase` łapie niewinne foldery

Kontekst: .gitignore repo (macOS, system plików case-insensitive)
Problem: wpis `Plans/` (bez kotwicy) przez `core.ignorecase` zignorował feature-folder `Plans/` wewnątrz źródeł — pliki nowego feature'a nie weszły do commita (IOS-00103); objaw wyglądał jak „git gubi pliki".
Reguła: Wzorce ignore dla folderów top-level zawsze kotwicz: `/PLANS/`, nie `PLANS/`. Po dopisaniu wzorca sprawdź `git status --ignored`, czy nie złapał za dużo.
Dotyczy: implement, impl-review
