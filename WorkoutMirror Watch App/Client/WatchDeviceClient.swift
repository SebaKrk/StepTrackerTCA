//
//  WatchDeviceClient.swift
//  WorkoutMirror Watch App
//
//  Created by Sebastian Ściuba on 11/09/2026.
//

import ComposableArchitecture
import WatchKit

/// TCA dependency for `WKInterfaceDevice` readings on the wrist.
///
/// watchOS has no low-battery notification API — the level must be polled.
struct WatchDeviceClient: Sendable {

    /// Current battery level in `0...1`, or `nil` when the reading is unavailable.
    /// Enables `isBatteryMonitoringEnabled` lazily on first read (the device
    /// reports `-1` until monitoring is on).
    var batteryLevel: @Sendable () async -> Double?

    /// Plays the `.notification` warning haptic on the wrist.
    var playWarningHaptic: @Sendable () async -> Void
}

// MARK: - Dependency

extension DependencyValues {
    var watchDeviceClient: WatchDeviceClient {
        get { self[WatchDeviceClientKey.self] }
        set { self[WatchDeviceClientKey.self] = newValue }
    }
}

private enum WatchDeviceClientKey: DependencyKey {
    static let liveValue = WatchDeviceClient(
        batteryLevel: {
            await MainActor.run {
                let device = WKInterfaceDevice.current()
                if !device.isBatteryMonitoringEnabled {
                    device.isBatteryMonitoringEnabled = true
                }
                let level = device.batteryLevel
                return level >= 0 ? Double(level) : nil
            }
        },
        playWarningHaptic: {
            await MainActor.run {
                WKInterfaceDevice.current().play(.notification)
            }
        }
    )
}
