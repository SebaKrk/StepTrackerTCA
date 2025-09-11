//
//  ConfigurationFeature.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 23/08/2025.
//

import ComposableArchitecture
import SwiftUI
import SharedModels
import HealthHub

@Reducer
struct ConfigurationFeature {
    
    // MARK: - Dependency
    
    @Dependency(\.dismiss) var dismiss
    @Dependency(\.continuousClock) var clock
    @Dependency(\.bluetoothClient) var client
    
    // MARK: - Reducer
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
                
                // MARK: - Core Action
            case let .core(.changeViewState(viewState)):
                state.viewState = viewState
                return .none
                
            case let .core(.bluetoothStatusChanged(status)):
                state.bluetoothStatus = status
                
                // Jeśli BluetoothFeature jest otwarty, przekaż mu status
                if case .bluetoothFeature = state.destination {
                    return .send(.destination(.presented(.bluetoothFeature(.bluetoothStatusChanged(status)))))
                }
                return .none
                
                // MARK: - View Action
            case .view(.viewDidAppear):
                return .run { send in
                    print("📱 ConfigurationFeature: Checking initial status...")
                    let initialStatus = await client.getCurrentStatus()
                    await send(.core(.bluetoothStatusChanged(initialStatus)))
                    
                    print("📱 ConfigurationFeature: Initializing Bluetooth...")
                    await client.initializeBluetooth()
                    
                    let finalStatus = await client.getCurrentStatus()
                    if finalStatus != initialStatus {
                        print("📱 ConfigurationFeature: Status changed after init: \(finalStatus)")
                        await send(.core(.bluetoothStatusChanged(finalStatus)))
                    }
                }
                
            case .view(.closeButtonTapped):
                return .run { send in
                    await self.dismiss()
                }
                
            case .view(.backToDeviceButtonTapped):
                return .send(.core(.changeViewState(.device)))
                
            case .view(.backToActivityButtonTapped):
                return .send(.core(.changeViewState(.activity)))
                
            case .view(.startButtonTapped):
                if state.selectedDevice == .mirror {
                    // Tu będzie odpalenie lustra po sprawdzeniu np czy na pewno mamy trwającą sesję na zegarku
                    return .none
                } else {
                    guard let workout = state.selectedWorkout else {
                        print("Błąd: Nie wybrano ćwiczenia")
                        return .none
                    }
                    return .run { send in
                        /// Ta akcja jest przekazywana do AppTabNewFeature gdzie następnie wywoływany jest .fullScreenCover
                        await send(.delegate(.start(workout)))
                        await self.dismiss()
                    }
                }
                
            case .view(.startScanningBluetoothButtonTapped):
                // Sprawdź aktualny status przed otwarciem BluetoothFeature
                return .run { send in
                    let currentStatus = await client.getCurrentStatus()

                    await send(.core(.bluetoothStatusChanged(currentStatus)))
                    
                    switch currentStatus {
                    case .ready:
                        await send(.core(.openBluetoothFeature))
                    case .disabled, .unauthorized:
                        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                            await UIApplication.shared.open(settingsUrl)
                        }
                    case .unknown:
                        // Status jeszcze się nie ustalił
                        break
                    default:
                        break
                    }
                }
                
            case .core(.openBluetoothFeature):
                state.destination = .bluetoothFeature(BluetoothFeature.State())
                return .none
                
                // MARK: - Child Action
            case .device(.select):
                switch state.selectedDevice {
                case .iphone, .watch:
                    return .run { send in
                        try await clock.sleep(for: .milliseconds(1250))
                        await send(.core(.changeViewState(.activity)), animation: .bouncy)
                    }
                case .mirror:
                    return .run { send in
                        try await clock.sleep(for: .milliseconds(1250))
                        await send(.core(.changeViewState(.ready)),
                                   animation: .bouncy)
                    }
                case .none:
                    return .none
                }
                
            case let .device(.view(.buttonTapped(option))):
                state.selectedDevice = option
                return .none
                
            case let .activity(.select(value)):
                state.selectedWorkout = value
                return .run { send in
                    try await clock.sleep(for: .milliseconds(1250))
                    await send(.core(.changeViewState(.ready)),
                               animation: .bouncy)
                }
                
                // MARK: - Delegate Action
            case .delegate(_):
                return .none
                
                // MARK: - Childs Action
            case .device(_):
                return .none
                
            case .activity(_):
                return .none
                
                // MARK: - Destination Action
            case .destination(.dismiss):
                // Po zamknięciu BluetoothFeature sprawdź status ponownie
                return .run { send in
                    let currentStatus = await client.getCurrentStatus()
                    await send(.core(.bluetoothStatusChanged(currentStatus)))
                }
                
            case .destination(_):
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
        Scope(state: \.device, action: \.device) {
            DeviceFeature()
        }
        Scope(state: \.activity, action: \.activity) {
            ActivityPickerFeature()
        }
    }
}

extension ConfigurationFeature {
    
    enum CancelID: Hashable, Sendable {
        case advance
    }
}

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
            case openBluetoothFeature
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
            case startScanningBluetoothButtonTapped
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

/// Implementation of `ConfigurationFeature` state
extension ConfigurationFeature {
    
    @ObservableState
    struct State {
        
        // MARK: - Properties
        
        /// Aktualny stan widoku konfiguracji (device/activity/ready)
        var viewState: SetupPhase = .device
        
        /// Aktualny status Bluetooth (ready/disabled/unknown etc.)
        var bluetoothStatus: BluetoothStatus = .unknown
        
        /// Wybrane urządzenie do treningu (iPhone/Watch/Mirror)
        var selectedDevice: DeviceOption? = nil
        
        /// Wybrany typ treningu
        var selectedWorkout: WorkoutType? = nil
        
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

/// Implementation of `ConfigurationFeature` destination
extension ConfigurationFeature {
    
    @Reducer
    enum Destination {
        /// BluetoothFeature destination dla skanowania i łączenia urządzeń
        case bluetoothFeature(BluetoothFeature)
    }
}
