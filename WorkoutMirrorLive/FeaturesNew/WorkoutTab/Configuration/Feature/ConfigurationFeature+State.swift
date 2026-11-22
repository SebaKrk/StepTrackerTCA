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

        /// Aktywność narzucona przez plan — wtedy krok wyboru aktywności nie istnieje,
        /// a wybór urządzenia od razu startuje trening.
        let lockedWorkout: WorkoutType?
        
        ///
        var isHeartRateConnected: Bool = false
        
        /// Liczba połączonych urządzeń (0, 1, 2)
        var connectionBadge: Int {
            var count = 0
            if isHeartRateConnected {
                count += 1
            }
            if watchConnectivityStatus == .ready {
                count += 1
            }
            return count
        }

        /// Whether the picked device is ready to measure; `nil` when this screen cannot tell.
        var isSelectedDeviceReady: Bool? {
            switch selectedDevice {
            case .watch:
                // The status is checked once on appear; until it lands the screen cannot tell.
                watchConnectivityStatus == .unknown ? nil : watchConnectivityStatus == .ready
            case .hrBelt:
                isHeartRateConnected
            case .airPods, .iphone, .mirror, nil:
                nil
            }
        }
        
        // MARK: - Destination
        
        /// Navigation destination state
        @Presents var destination: Destination.State?
        
        // MARK: - Child
        
        /// DeviceFeature child state
        var device: DeviceFeature.State = .init()

        // MARK: - Init

        /// `lockedWorkout` set means the caller already knows the activity (a plan start).
        init(lockedWorkout: WorkoutType? = nil) {
            self.lockedWorkout = lockedWorkout
            self.selectedWorkout = lockedWorkout
        }
        
        /// ActivityPickerFeature child state
        var activity: ActivityPickerFeature.State = .init()
    }
}
