//
//  PowerModeClient.swift
//  MyFitnessJournal
//
//  Created by Sebastian Ściuba.
//

import ComposableArchitecture
import Foundation

/// Reads whether this device is in Low Power Mode.
struct PowerModeClient {

    /// Returns `true` while Low Power Mode is on.
    var isLowPowerModeEnabled: @Sendable () -> Bool
}

extension DependencyValues {

    /// This device's Low Power Mode state.
    var powerMode: PowerModeClient {
        get { self[PowerModeClientKey.self] }
        set { self[PowerModeClientKey.self] = newValue }
    }
}

private enum PowerModeClientKey: DependencyKey {
    static let liveValue = PowerModeClient(
        isLowPowerModeEnabled: { ProcessInfo.processInfo.isLowPowerModeEnabled }
    )
    static let testValue = PowerModeClient(
        isLowPowerModeEnabled: { false }
    )
}
