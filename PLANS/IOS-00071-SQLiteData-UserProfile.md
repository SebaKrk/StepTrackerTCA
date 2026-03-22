# IOS-00071: SQLiteData Architecture + UserProfile

## Kontekst

Aplikacja nie ma własnego storage dla danych użytkownika niezwiązanych z HealthKit (imię, nazwisko, nickname). HealthKit nie przechowuje imienia. Celem jest:
1. Zbudowanie skalowalnej architektury SQLiteData (produkcyjny storage)
2. Wydzielenie persistence layer do osobnego pakietu `AppDatabase`
3. Pierwsza encja: `UserProfile` (name, surname, nickname, email)
4. UI: wyświetlenie w `PersonSettingsView` + modal do edycji

---

## Architektura warstw

```
SharedModels          → pure domain (UserProfile)           ← bez SQLiteData
AppDatabase (NEW pkg) → @Table records + Schema.swift       ← zna SQLiteData + SharedModels
WorkoutMirrorLive     → UserProfileClient, Feature, Views   ← importuje AppDatabase
Watch App             → importuje tylko SharedModels        ← nie zna bazy
```

---

## Subtaski

### KROK 1 — `UserProfile` domain model w SharedModels ✅

**Plik:** `SharedModels/Sources/SharedModels/UserProfile/UserProfile.swift`

```swift
public struct UserProfile: Identifiable, Equatable, Codable, Sendable {
    public let id: UUID
    public var email: String
    public var name: String
    public var surname: String
    public var nickname: String
}
```

---

### KROK 2 — Nowy pakiet `AppDatabase` ✅

**Lokalizacja:** `StepTrackerTCA/AppDatabase/`

**Pliki:**
- `CloudKitSyncable.swift` — protokół (createdAt, updatedAt, ckRecordData)
- `Schema.swift` — bootstrapDatabase() + DatabaseMigrator
- `Records/UserProfileRecord.swift` — @Table + mapowanie do/z UserProfile

**Migracje:**
- `v1_userProfile` — CREATE TABLE userProfileRecords
- `v2_addEmail` — ALTER TABLE ADD COLUMN email

---

### KROK 3 — AppDatabase dodany do Xcode target ✅

Wykonane ręcznie przez użytkownika w Xcode.

---

### KROK 4 — `bootstrapDatabase()` w app entry point ✅

**Plik:** `WorkoutMirrorLive/WorkoutMirrorLiveApp.swift`

```swift
init() {
    prepareDependencies {
        do {
            try $0.bootstrapDatabase()
        } catch {
            fatalError("Database failed to initialize: \(error)")
        }
    }
}
```

---

### KROK 5 — `UserProfileClient` ✅

**Plik:** `.../PersonSettings/Client/UserProfileClient.swift`

```swift
struct UserProfileClient: Sendable {
    var save: @Sendable (UserProfile) async throws -> Void
    var fetch: @Sendable () async throws -> UserProfile?
}
```

- `save`: upsert po id (singleton record)
- `fetch`: `fetchOne` z `order { $0.updatedAt.desc() }`
- `@Dependency(\.date.now)` przechwycone wewnątrz closure save

---

### KROK 6 — `PersonSettingsFeature` — ładowanie profilu ✅

- `PersonSettingsFeature+State.swift` — `var userProfile: UserProfile?`
- `PersonSettingsFeature+Action.swift` — `fetchUserProfile`, `profileLoaded`, `editProfileTapped`
- `PersonSettingsFeature+Destination.swift` — `.editProfile(PersonProfileEditFeature)`
- `PersonSettingsFeature.swift` — fetch na viewDidAppear, delegate .profileSaved → fetchUserProfile

---

### KROK 7 — `PersonProfileEditFeature` ✅

**Pliki:** `PersonProfileEditFeature.swift` + `+State.swift` + `+Action.swift`

- `BindingReducer` + `$store.name` (unika TCA warning przy dismissal)
- `id: UUID` w State — zachowany z profilu, zapewnia UPSERT zamiast INSERT
- delegate `.profileSaved` → PersonSettingsFeature fetchuje odświeżony profil

---

### KROK 8 — `PersonSettingsView` + `PersonProfileEditView` ✅

- `PersonSettingsView` — wyświetlenie danych + `.sheet` dla editProfile
- `PersonProfileEditView` — TextField dla każdego pola, Save/Cancel
- `coreMetricsCell` obsługuje nil/empty przez `if let value, !value.isEmpty`

---

### KROK 9 — Previews ✅

- `PersonSettingsView` — `#Preview` z `try! $0.bootstrapDatabase()`
- `PersonProfileEditView` — `#Preview` z `try! $0.bootstrapDatabase()`

---

## Weryfikacja end-to-end

- [x] App startuje bez crashu
- [x] PersonSettingsView ładuje dane (lub "-")
- [x] Edit otwiera modal z pre-filled polami
- [x] Save → modal zamknięty, widok odświeżony
- [x] Kill + restart → dane nadal widoczne
- [x] Preview działa
