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
                return .none
                
                // MARK: - View Action
            case .view(.viewDidAppear):
                return .run { send in
                    await client.initializeBluetooth()
                    
                    // Nasłuchuj zmian statusu
                    for await status in await client.bluetoothStatusUpdates() {
                        await send(.core(.bluetoothStatusChanged(status)))
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
                    // Tu bedzie odpalnie lusta po sprawdzeniu np czy na pewno mamy trawajaca sesje na zegarku
                    return .none
                } else {
                    guard let workout = state.selectedWorkout else {
                        print("Bład: Nie wybrano ćwiczenia")
                        return .none
                    }
                    return .run { send in
                        /// ta akacja jest przekazywana do AppTabNewFeature gdzie następnie wywoływany jest .fullScreenCover
                        await send(.delegate(.start(workout)))
                        await self.dismiss()
                    }
                }
                
            case .view(.startScanningBluetoothButtonTapped):
                // Sprawdź status przed otwarciem sheeta
                switch state.bluetoothStatus {
                case .ready:
                    state.destination = .bluetoothFeature(BluetoothFeature.State())
                case .disabled, .unauthorized:
                    // Otwórz ustawienia zamiast sheeta
                    return .run { _ in
                        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                            await UIApplication.shared.open(settingsUrl)
                        }
                    }
                case .unknown:
                    break
                default:
                    break
                }
                
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
            
            ///
            case changeViewState(SetupPhase)
            
            ///
            case bluetoothStatusChanged(BluetoothStatus)
            
        }
        
        // MARK: - View Actions
        
        case view(View)
        
        enum View {
            
            /// Action triggered when the view appears on the screen.
            case viewDidAppear
            
            ///
            case closeButtonTapped
            
            ///
            case backToDeviceButtonTapped
            
            ///
            case backToActivityButtonTapped
            
            ///
            case startButtonTapped
            
            ///
            case startScanningBluetoothButtonTapped
        }
        
        // MARK: - Delegate Actions
        
        case delegate(DelegateAction)
        
        enum DelegateAction: Equatable {
            
            ///
            case start(WorkoutType)
        }
        
        // MARK: - Destination
                
        /// destination case for navigation
        case destination(PresentationAction<Destination.Action>)
        
        // MARK: - Child
        
        ///
        case device(DeviceFeature.Action)
        
        ///
        case activity(ActivityPickerFeature.Action)

    }
}

/// Implementation of `ConfigurationFeature` state
extension ConfigurationFeature {
    
    @ObservableState
    struct State {
        
        // MARK: - Properties
        
        ///
        var viewState: SetupPhase = .device
        
        ///
        var bluetoothStatus: BluetoothStatus = .unknown
        
        ///
        var selectedDevice: DeviceOption? = nil
        
        ///
        var selectedWorkout: WorkoutType? = nil
        
        // MARK: - Destination
        
        /// destination from ConfigurationFeature
        @Presents var destination: Destination.State?
        
        // MARK: - Child
        
        ///
        var device: DeviceFeature.State = .init()
        
        ///
        var activity: ActivityPickerFeature.State = .init()
        
    }
    
}

/// Implementation of `ConfigurationFeature` destination
extension ConfigurationFeature {
    
    @Reducer
    enum Destination {
        
        /// Represents the destination for displaying in `BluetoothFeature`
        case bluetoothFeature(BluetoothFeature)
    }
    
}
