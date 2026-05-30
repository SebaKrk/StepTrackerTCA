//
//  AppLogger.swift
//  SharedModels
//
//  Created by Sebastian Sciuba on 14/04/2026.
//

import OSLog

/// Centralized `Logger` instances for the WorkoutMirror app family.
///
/// Both the iPhone app and the Watch app share this definition via SharedModels.
/// Filter logs in Console.app by subsystem `com.ss.WorkoutMirror`,
/// then narrow by category to isolate a specific module.
///
/// After a physical workout (no Mac connected), collect logs with:
/// ```bash
/// xcrun devicectl device process log collect \
///   --device <UDID> \
///   --output ~/Desktop/workout.logarchive
/// ```
/// Then open the `.logarchive` in Console.app and search for `com.ss.WorkoutMirror`.
///
/// **Log levels:**
/// - `.debug`  — high-frequency / verbose, stripped in release builds
/// - `.info`   — lifecycle events (session start/stop, pause/resume, mirroring)
/// - `.error`  — failures that affect correctness (HealthKit errors, save failures)
extension Logger {

    private static let subsystem = "com.ss.WorkoutMirror"

    // MARK: - Watch App

    /// `WatchWorkoutSessionClient` / `WatchWorkoutSessionManager`
    /// Covers: session start, mirroring, stop sequence, finishWorkout, pause/resume.
    public static let watchSession = Logger(subsystem: subsystem, category: "WatchSession")

    /// `HRMirrorFeature`
    /// Covers: sessionStateChanged, pause/resume sync, subSecondTimer, hrReceived.
    public static let hrMirror = Logger(subsystem: subsystem, category: "HRMirror")

    /// `AppFeatureAW`
    /// Covers: workoutConfigurationReceived, workoutStarted, workoutEnded, dismissHRMirror.
    public static let appAW = Logger(subsystem: subsystem, category: "AppAW")

    // MARK: - iPhone App

    /// `SessionFeature` + `WorkoutModeRouter`
    /// Covers: mode decision (Watch-primary vs iPhone-standalone), session lifecycle, tick.
    public static let session = Logger(subsystem: subsystem, category: "Session")

    /// `DefaultTrainingManager` + `TrainingSessionStateControl`
    /// Covers: mirrored session received, pause/resume/end on iPhone, workout fetch.
    public static let trainingManager = Logger(subsystem: subsystem, category: "TrainingManager")

    /// `iPhoneWorkoutSession` (iOS 26+ native Tor B — iPhone-primary with BLE HR sensor).
    /// Covers: prepare/start/pause/resume/end lifecycle, HK builder data collection, BLE pair events.
    public static let iPhoneWorkoutSession = Logger(subsystem: subsystem, category: "iPhoneWorkoutSession")

    /// `StatsFeature` + Stats tab children.
    /// Covers: HealthKit authorization, observation lifecycle, child feature initialization.
    public static let stats = Logger(subsystem: subsystem, category: "Stats")

    // MARK: - Shared

    /// `DefaultWatchConnectivityManager` + `WatchConnectivity+Delegate`
    /// Covers: activation, send/receive events, reachability.
    public static let wc = Logger(subsystem: subsystem, category: "WatchConnectivity")

    /// `DefaultCentralManager` + `BluetoothStatusActor` + `BluetoothScanActor` + `BluetoothClient`
    /// Covers: BT state changes, scan start/stop, connect/disconnect, errors.
    public static let bluetooth = Logger(subsystem: subsystem, category: "Bluetooth")

    /// `GymRoomFeature` + `JoinLiveClassFeature` + `PeerMirrorService` + `PeerMirrorBLE*Session`
    /// Covers: peer discovery, BLE pairing, HR broadcast iPhone → iPad, room lifecycle.
    public static let gymRoom = Logger(subsystem: subsystem, category: "GymRoom")
}
