//
//  ConfigurationFeature+Action.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 12/09/2025.
//

import ComposableArchitecture
import SwiftUI
import SharedModels
import HealthHub

/// Implementation of `ConfigurationFeature` action
extension ConfigurationFeature {
    
    @CasePathable
    enum Action: ViewAction {
        
        // MARK: - Core Actions
        
        case core(Internal)
        
        enum Internal {
            /// Zmiana stanu widoku (device/activity/ready)
            case changeViewState(SetupPhase)
            
            /// Aktualizacja statusu Bluetooth w ConfigurationFeature
            case bluetoothStatusChanged(BluetoothStatus)
            
            /// Otwórz BluetoothFeature sheet
            case openBluetoothFeature(BluetoothStatus)
            
            case startBluetoothStatusMonitoring
        }
        
        // MARK: - View Actions
        
        case view(View)
        
        enum View {
            /// Widok się pojawił - sprawdź status Bluetooth
            case viewDidAppear
            
            /// User nacisnął przycisk zamknięcia
            case closeButtonTapped
            
            /// User nacisnął przycisk powrotu do wyboru urządzenia
            case backToDeviceButtonTapped
            
            /// User nacisnął przycisk powrotu do wyboru aktywności
            case backToActivityButtonTapped
            
            /// User nacisnął przycisk START
            case startButtonTapped
            
            /// User nacisnął przycisk skanowania Bluetooth
            case scanningBluetoothButtonTapped

        }
        
        // MARK: - Delegate Actions
        
        case delegate(DelegateAction)
        
        enum DelegateAction: Equatable {
            /// Rozpocznij trening z wybranym typem ćwiczenia
            case start(WorkoutType)
        }
        
        // MARK: - Destination
        
        /// Navigation destination actions
        case destination(PresentationAction<Destination.Action>)
        
        // MARK: - Child
        
        /// DeviceFeature child actions
        case device(DeviceFeature.Action)
        
        /// ActivityPickerFeature child actions
        case activity(ActivityPickerFeature.Action)
    }
}
