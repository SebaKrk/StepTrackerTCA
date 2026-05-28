# IPAD-0087-F · Known Issues + Empirical Measurements (BLE Direct)

**Autor**: Sebastian Ściuba
**Data utworzenia**: 2026-05-25
**Status**: Template — uzupełnij po smoke teście na real devices (Subtask F.E)

---

## 🧪 Smoke test scenarios — wyniki

Wszystkie testy na **real devices** (BLE w simulatorze nie działa wiarygodnie).

### 1. Cross-network connection (iPhone 5G, iPad Wi-Fi boxu)

- [ ] Wykonany?
- **Setup**: iPhone z wyłączonym Wi-Fi (na 5G/LTE), iPad podłączony do Wi-Fi boxu.
- **Expected**: Połączenie BLE ustanawia się w <3s, HR samples lecą.
- **Result**: _do uzupełnienia_
- **Latency observed (avg → p95)**: _ms → _ms

### 2. No-network connection (oba devices bez Wi-Fi)

- [ ] Wykonany?
- **Setup**: iPhone i iPad oba bez Wi-Fi (Airplane Mode + Bluetooth ON).
- **Expected**: Połączenie BLE działa (radio direct, zero infrastruktury).
- **Result**: _do uzupełnienia_

### 3. Multi-user (2-3 iPhone'y jednocześnie)

- [ ] Wykonany?
- **Setup**: 2-3 fizyczne iPhone'y join jeden iPad simultaneously.
- **Expected**: Wszystkie tile pojawiają się na iPad, HR aktualizuje się per tile.
- **Result**: _do uzupełnienia_
- **Concurrent connections observed**: _ (z tyle fizycznych devices) _

### 4. Proximity disconnect (user wychodzi z sali)

- [ ] Wykonany?
- **Setup**: iPhone connected, oddal się ~30m+ od iPada.
- **Expected**: Tile znika w <10s (BLE timeout + reconnect attempt failed).
- **Result**: _do uzupełnienia_
- **Disconnect time observed**: _s

### 5. Stress test capacity (max concurrent)

- [ ] Wykonany?
- **Setup**: Dodawaj iPhone'y jeden po drugim, monitor moment gdy iPad odmawia kolejnego connection.
- **Result**: _Apple nie publikuje hard BLE concurrent connection limit_ — wartość empiryczna 2026:
- **Max concurrent connections**: _ (target: 15+, fallback acceptable: 8+) _
- **iPad model tested**: _

### 6. Background tolerance (iPhone w kieszeni z workout session)

- [ ] Wykonany?
- **Setup**: iPhone w kieszeni z aktywnym `HKWorkoutSession`, ekran wyłączony.
- **Expected**: HR dalej leci przez BLE (workout session trzyma app live + `bluetooth-central` background mode).
- **Result**: _do uzupełnienia_

### 7. iPad rotation/sleep tolerance

- [ ] Wykonany?
- **Setup**: iPad w foreground (kiosk mode), display dim'a po 60s.
- **Expected**: BLE peripheral dalej advertise + accept connections.
- **Result**: _do uzupełnienia_

---

## 📊 Battery impact

- **iPad po 1h class (15 concurrent connections)**: _% spadek
- **iPhone po 1h workout (BLE + HealthKit)**: _% spadek

---

## ⚠️ Edge cases

### BLE permission denied

- [ ] Tested
- **Behavior observed**: _
- **UX recommendation**: _

### Bluetooth turned off mid-class

- [ ] Tested
- **Behavior observed**: _
- **Recovery**: _

### iPad app suspended mid-class (np. przypadkowy home button)

- [ ] Tested
- **Behavior observed**: _
- **Recovery**: _

### iPhone reconnect po out-of-range → return-to-range

- [ ] Tested
- **Reconnect time**: _s (exponential backoff: 1s → 2s → 4s → 8s → cap 30s)

### BLE failure feedback dla user'a — świadomie pominięte

- [x] **Decyzja podjęta**: silent recovery, brak UI feedback (data: 2026-05-28)
- **Co user widzi**: jednolite "Looking for class..." dla wszystkich failure cases (transient + persistent)
- **Rationale**: większość failurów transient (5-10s recovery w tle dzięki naprawom F.A + F.C), explicit feedback by powodował false alarms przy normalnych RSSI dip / wadliwym discovery
- **Akceptowalne dla**: PoC testowanego przez Sebastian + 2-3 testerów z Console.app access
- **NIE akceptowalne dla**: external beta / production — user bez Console nie odróżni "BT off" od "klasa nie wystartowała" od "transient retry"
- **Failure cases które wyglądają identycznie**:
  - BT off (permission denied / system off) — wymaga user action (Settings → BT on)
  - Brak iPada w sali (klasa nie wystartowała) — wymaga akcji trenera
  - Wadliwy peripheral discovery (corrupted GATT) — system recover automatycznie ~5-10s
  - Persistent reconnect failure (peripheral fizycznie poza zasięgiem >30m) — system retry w nieskończoność z backoff
- **Future ticket**: `IPAD-0099 — Connection failure UX`
  - Rozszerz `PeerEvent` enum o `.discoveryRejected(reason:)` + `.bluetoothUnavailable(reason:)`
  - W `JoinLiveClassFeature` dodaj timer 15s w `.searching` → emit `.showSearchHint`
  - Toast banner "Nie mogę znaleźć Gym Room. Sprawdź czy trener wystartował klasę i Bluetooth jest włączony." + button "Spróbuj ponownie"
  - Dla `.bluetoothUnavailable(.unauthorized)` osobny komunikat z deep-linkiem do Settings

---

## 🎯 Decyzja po smoke test'cie

**Production ready?**
- [ ] TAK — BLE wystarcza dla typowych boxów (15+ concurrent).
- [ ] NIE — wymaga cloud server scale-up (otwórz IPAD-0100).

**Notes**: _
