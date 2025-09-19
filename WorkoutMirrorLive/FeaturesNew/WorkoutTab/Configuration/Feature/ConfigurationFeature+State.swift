//
//  ConfigurationFeature+State.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 12/09/2025.
//

import ComposableArchitecture
import SwiftUI
import SharedModels
import HealthHub

/// Implementation of `ConfigurationFeature` state
extension ConfigurationFeature {
    
    @ObservableState
    struct State {
        
        // MARK: - Properties
        
        /// Aktualny stan widoku konfiguracji (device/activity/ready)
        var viewState: SetupPhase = .device
        
        /// Aktualny status Bluetooth (ready/disabled/unknown etc.)
        var bluetoothStatus: BluetoothStatus = .unknown
        
        ///
        var watchConnectivityStatus: WatchConnectivityStatus = .unknown
        
        /// Wybrane urządzenie do treningu (iPhone/Watch/Mirror)
        var selectedDevice: DeviceOption? = nil
        
        /// Wybrany typ treningu
        var selectedWorkout: WorkoutType? = nil
        
        ///
        var isHeartRateConnected: Bool = false
        
        // MARK: - Destination
        
        /// Navigation destination state
        @Presents var destination: Destination.State?
        
        // MARK: - Child
        
        /// DeviceFeature child state
        var device: DeviceFeature.State = .init()
        
        /// ActivityPickerFeature child state
        var activity: ActivityPickerFeature.State = .init()
    }
}
