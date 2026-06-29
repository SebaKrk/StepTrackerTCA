<h1 align="center">MyFitnessJournal</h1>
<p align="center">
  <em>A personal training journal for iPhone, iPad & Apple Watch.</em><br>
  <sub>repo: <code>StepTrackerTCA</code></sub>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Swift-6.2-F05138?logo=swift&logoColor=white" alt="Swift 6.2">
  <img src="https://img.shields.io/badge/iOS-26.0+-000000?logo=apple&logoColor=white" alt="iOS 26+">
  <img src="https://img.shields.io/badge/iPadOS-26.0+-000000?logo=apple&logoColor=white" alt="iPadOS 26+">
  <img src="https://img.shields.io/badge/watchOS-26.0+-000000?logo=apple&logoColor=white" alt="watchOS 26+">
  <img src="https://img.shields.io/badge/Architecture-TCA-7B61FF" alt="TCA">
  <img src="https://img.shields.io/badge/SwiftUI-Liquid%20Glass-blue" alt="SwiftUI">
</p>

<p align="center">
  A multi-platform fitness ecosystem built with <strong>SwiftUI</strong> and
  <strong>The Composable Architecture</strong>. What started as a TCA learning exercise
  (inspired by Sean Allen's course) grew into a modular system of
  <strong>two products sharing one foundation</strong> of local Swift packages.
</p>

---

## 🎯 Vision

Build a **personal-yet-extensible** fitness platform that:

- **Treats your workouts as data you own** — local-first SQLite storage with CloudKit
  sync across your devices, no third-party cloud or analytics.
- **Bridges the consumer-grade Apple Health ecosystem with serious training tools** —
  CrossFit / strength athletes get per-WOD score tracking, training readiness,
  per-exercise analytics, heart-rate zones and on-device AI plan parsing, all on top of
  HealthKit primitives.
- **Scales from solo athlete to group gym** — the same domain core powers a personal
  iPhone+Watch journal **and** an iPad coach dashboard that monitors a roomful of
  athletes over Bluetooth.
- **Demonstrates modern iOS architecture in production** — strict Swift 6 concurrency,
  TCA composition, Strategy/Client patterns, modular SPM packages with CloudKit sync,
  and a SwiftUI "view facade" convention separating structure from styling.

---

## 📱 MyFitnessJournal — personal training journal (iPhone + Watch)

A personal companion for tracking workouts, recovery and progress.

- **Live workouts with heart-rate tracking** — a single session started and controlled
  from either iPhone or Apple Watch, mirrored across both devices
  (`HKWorkoutSession` + `WatchConnectivity`). Watch-primary and iPhone-primary modes
  with BLE HR sensor support (iOS 26 native).
- **Plan scanning with on-device AI & OCR** — photograph a training plan / WOD and the
  app extracts the exercises. Three pluggable strategies (Strategy pattern):
  **Apple Foundation Models**, **Claude API**, and a custom parser.
- **Post-workout structured journal** — per-WOD score tracking
  (forTime / AMRAP / forLoad / completed), per-exercise weight & reps with set-by-set
  detail for strength workouts, scaling levels (Rx / Scaled / Rx+), PR flag.
- **Heart-rate zones with selectable formula** — choose from Tanaka, Nes, Gulati,
  Fairbarn (sex-aware) or Classic. Per-workout snapshot freeze: your zones stay
  consistent even if you change the formula later.
- **Analytics & trends** — training readiness score, heart-rate zone distribution,
  weight trend, training volume per category, per-exercise PR / 1RM analytics.
- **Manual entry escape hatch** — re-attach a plan to a workout retroactively from
  History, useful when the live save flow misses (e.g., WatchConnectivity drops).
- **Health journal** — weight, goals, HealthKit metrics, home-screen widgets and Live
  Activities for active workouts.

### Screenshots

> Drop the screenshot files into `docs/screenshots/` using the names below and they'll
> render automatically.

#### Training Readiness — the first screen you see

The dashboard adapts to your daily recovery state. Two snapshots from the same week:

<p align="center">
  <img src="docs/screenshots/01a-readiness-low.png" width="280" alt="Low readiness day">
  &nbsp;&nbsp;
  <img src="docs/screenshots/01b-readiness-high.png" width="280" alt="High readiness day">
</p>

<p align="center">
  <em>Left: low-readiness day (RHR / HRV / sleep flagged red).
  Right: high-readiness day (full green across all metrics).</em>
</p>

#### Stat drill-downs — any tile taps into a weekly detail

Every metric on the Today dashboard (HRV, sleep, activity, RHR, ...) opens its own
detail screen with a weekly chart, score points, average and an explanation of what
the metric means and how to act on it:

<p align="center">
  <img src="docs/screenshots/19-stat-sleep.png" width="220" alt="Sleep detail — weekly hours chart">
  &nbsp;
  <img src="docs/screenshots/04-activity-trend.png" width="220" alt="Activity detail — weekly kcal chart">
  &nbsp;
  <img src="docs/screenshots/20-stat-hrv.png" width="220" alt="HRV detail — weekly ms chart">
</p>

<p align="center">
  <em>Same layout per metric: current value + status + score chip on top, weekly
  chart with average dashed line in the middle, contextual explanation on the bottom.</em>
</p>

#### Analytics & trends

<p align="center">
  <img src="docs/screenshots/02-analytics.png" width="280" alt="Analytics — volume + weight">
  &nbsp;
  <img src="docs/screenshots/03-exercise-balance.png" width="280" alt="Exercise balance per movement category">
</p>

<p align="center">
  <em>Training volume bars per workout category + weight trend line (left),
  exercise balance pie per movement type (right).</em>
</p>

#### Workout journal

<p align="center">
  <img src="docs/screenshots/05-activities-list.png" width="220" alt="Activities list">
  &nbsp;
  <img src="docs/screenshots/06-workout-detail.png" width="220" alt="Workout detail with HR chart">
  &nbsp;
  <img src="docs/screenshots/07-wod-plan.png" width="220" alt="WOD plan detail">
</p>

<p align="center">
  <em>Workout history list, per-workout detail with heart-rate over time (color-coded by
  zone) + zone distribution, full WOD plan with warmup / WOD / cooldown and per-exercise
  scaling.</em>
</p>

#### Live HR zones — real-time heart rate monitoring

During a workout the app streams heart rate in real time from either a paired
**BLE chest strap** (Polar H10, Wahoo TICKR, etc. via `HKLiveWorkoutDataSource`)
or **Apple Watch** (`HKWorkoutSession` mirroring channel — reliable even when
WatchConnectivity is unreachable). The whole UI repaints to the current zone
color so the athlete sees their intensity at a glance:

<p align="center">
  <img src="docs/screenshots/13-zone-resting.png" width="130" alt="Resting zone (38% maxHR)">
  &nbsp;
  <img src="docs/screenshots/14-zone-recovery.png" width="130" alt="Recovery zone (55% maxHR)">
  &nbsp;
  <img src="docs/screenshots/15-zone-fatburning.png" width="130" alt="Fat Burning zone (65% maxHR)">
  &nbsp;
  <img src="docs/screenshots/16-zone-aerobic.png" width="130" alt="Aerobic zone (75% maxHR)">
  &nbsp;
  <img src="docs/screenshots/17-zone-threshold.png" width="130" alt="Threshold zone (85% maxHR)">
  &nbsp;
  <img src="docs/screenshots/18-zone-anaerobic.png" width="130" alt="Anaerobic zone (95% maxHR)">
</p>

<p align="center">
  <em>Six zones from Resting (gray, 38%) through Recovery, Fat Burning, Aerobic,
  Threshold, up to Anaerobic (red, 95%). Live BPM, %maxHR, calories, session avg/max
  and elapsed time — all updated per HR sample, no polling.</em>
</p>

---

## 🏋️ GymRoom — coach dashboard for group classes (iPad)

A trainer-facing iPad app for running **group fitness classes** — think a tablet on the
gym wall.

- **Create & run group classes** with class templates, schedule, and live monitoring.
- **Real-time heart-rate of every participant** — one tile per athlete, color-coded by
  heart-rate zone, so the coach sees the whole room at a glance.
- **Join via QR + BLE peer-to-peer** — a participant scans a QR code and streams heart
  rate to the iPad over Bluetooth, no cloud required (custom GATT protocol + peer
  identity handshake with reconnect grace).
- **Class history with charts** — per-athlete HR ranges (BarMark per minute, color
  gradient by zone), donut for class-wide time-in-zones, calories distribution,
  long-press scrub with RuleMark + popup.
- **Connection robustness** — BLE peer resume on reconnect (no duplicate athletes when
  someone runs outside class range), file logging exportable through the Files app.

### Screenshots

<p align="center">
  <img src="docs/screenshots/08-gymroom-live-class.png" width="400" alt="Gym Room live with 4 athletes">
  &nbsp;
  <img src="docs/screenshots/09-gymroom-live-full.png" width="400" alt="Gym Room full class with QR code">
</p>

<p align="center">
  <img src="docs/screenshots/10-gymroom-class-combined.png" width="265" alt="HR over time — combined view">
  &nbsp;
  <img src="docs/screenshots/11-gymroom-class-individual.png" width="265" alt="HR over time — per athlete">
  &nbsp;
  <img src="docs/screenshots/12-gymroom-class-zones.png" width="265" alt="Time in zones stacked bar">
</p>

<p align="center">
  <em>Top: live class monitoring — one tile per athlete (left) and full class with QR
  pairing for new participants (right). Bottom: post-class analytics — combined HR
  over time, per-athlete BarMark ranges by minute, and stacked time-in-zones.</em>
</p>

---

## 🏗️ Architecture

The two apps share a foundation of **local Swift packages**, so domain logic, models
and services are reused across iPhone, iPad and Watch:

| Package | Responsibility |
|---|---|
| **SharedModels** | Shared domain models, enums and constants (multi-platform) |
| **HealthHub** | HealthKit, WatchConnectivity, Bluetooth, workout parsing, training calculations |
| **AppDatabase** | SQLite persistence (SQLiteData) with CloudKit sync — users, sessions, exercise logs, HR snapshots |
| **PeerMirror** | BLE peer-to-peer heart-rate streaming (host/peer, GATT, peer identity) |
| **Commons** | Shared utilities, no external dependencies |

### Patterns & principles

- **TCA composition** — reducers for all business logic, `@Presents` + Destination
  for navigation, `@Shared(.appStorage)` for persisted preferences, `IdentifiedArrayOf`
  + `forEach` for collections of child features.
- **Client / Service boundary** — `@DependencyClient` structs as injectable boundary,
  `Service` (actor/class) as implementation hidden behind the client. Reuse via
  `@Dependency(\.xxxClient)`.
- **Strategy pattern** — pluggable algorithms (HR formulas, workout parsers, sex-aware
  variants) selected at runtime via enum + dispatch.
- **Snapshot pattern** — per-workout HR formula freeze: snapshot table captures
  `(maxHR, formula, age, sex)` at workout-end so historical zones never shift when
  preferences change.
- **View Facade** — SwiftUI views describe **structure** at the top (composition of
  named subviews), **implementation** at the bottom (`private var` / `private func`
  blocks). Makes diffs reviewable and snapshot-testable per section.
- **SOLID** — single responsibility per reducer / per cell / per service, open-closed
  for extensions (e.g., adding a new HR formula = one struct + one enum case + one
  switch branch).
- **Swift 6 strict concurrency** — `Sendable` everywhere, `@Shared` declared **inside**
  closures in TCA `liveValue` to avoid captured-var concurrency errors, AsyncStream
  multicast pattern for streams with multiple subscribers (view remount, TCA cancel).

---

## 🛠️ Tech stack

**Language & platform**: Swift 6.2 · iOS 26 / iPadOS 26 / watchOS 26 · Xcode 16+
(strict concurrency mode, `defaultIsolation(MainActor.self)`).

**Apple frameworks**: SwiftUI · HealthKit · WatchConnectivity · CoreBluetooth ·
WidgetKit · ActivityKit · Charts · Vision (OCR) · MapKit · CloudKit · App Intents.

**Third-party (Point-Free)**: TCA (Composable Architecture) · SQLiteData ·
SwiftNavigation · Dependencies · Sharing · IdentifiedCollections · CasePaths ·
Perception · IssueReporting.

**AI**: Apple Foundation Models (on-device) · Anthropic Claude API (`claude-sonnet-4-5`).

---

<details>
<summary><strong>About / Origins</strong> — how this project started</summary>

<br>

Inspired by Sean Allen's course, I decided to transform his application by adapting it
to the TCA (The Composable Architecture) framework. The goal of this project is to gain
a deep understanding of TCA by implementing modern design patterns and creating a
modular, scalable application following best practices.

The results of my work and the details of each step can be found on GitHub:
[StepTrackerTCA](https://github.com/SebaKrk/StepTrackerTCA). This project is not only a
technical exercise but also an exploration of possibilities and best practices in the
context of modern iOS app development.

- [Sean Allen](https://github.com/sallen0400) — Sean's GitHub profile
- [Sean Allen Teachable — Portfolio Project](https://seanallen.teachable.com/p/portfolio-project) — direct link to the course

</details>

---

## 📚 More

- 📌 **Feature Diagram:** [FeatureDiagram.md](https://github.com/SebaKrk/StepTrackerTCA/blob/develop/FeatureDiagram.md)
- 📌 **Database Schema:** [CoreDataDiagram.md](https://github.com/SebaKrk/StepTrackerTCA/blob/develop/CoreDataDiagram.md) *(historical name — uses SQLiteData)*
- 📌 **Task backlog:** [TASKS.md](TASKS.md)
