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
    @Dependency(\.bluetoothClient) var bluetoothClient
    @Dependency(\.watchConnectivityClient) var watchConnectivityClient
    
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
                
                /// Jeśli BluetoothFeature jest otwarty, przekaż mu status
                if case .bluetoothFeature = state.destination {
                    return .send(.destination(.presented(.bluetoothFeature(.bluetoothStatusChanged(status)))))
                }
                return .none
                
            case .core(.startBluetoothStatusMonitoring):
                return .run { send in
                    let statusStream = await bluetoothClient.statusUpdates()
                    
                    for await status in statusStream {
                        await send(.core(.bluetoothStatusChanged(status)))
                    }
                }
                .cancellable(id: "bluetoothStatusMonitoring")
                
            case let .core(.watchConnectivityStatusChange(status)):
                state.watchConnectivityStatus = status
                return .none
                
                // MARK: - View Action
            case .view(.viewDidAppear):
                return .concatenate(
                    .run { _ in
                        await bluetoothClient.initializeBluetooth()
                        await watchConnectivityClient.initializeWatchConnectivity()
                    },
                    .run { send in
                        let finalStatus = await bluetoothClient.getCurrentStatus()
                        await send(.core(.bluetoothStatusChanged(finalStatus)))
                    },
                    .send(.core(.startBluetoothStatusMonitoring)),
                    .run { send in
                        let status = await watchConnectivityClient.checkWatchStatus()
                        await send(.core(.watchConnectivityStatusChange(status)))
                    }
                )
                
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
                
            case .view(.scanningBluetoothButtonTapped):
                return .run { [bluetoothStatus = state.bluetoothStatus] send in
                    switch bluetoothStatus {
                    case .ready:
                        await send(.core(.openBluetoothFeature(bluetoothStatus)))
                        
                    case .unauthorized, .disabled:
                        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                            await MainActor.run {
                                if UIApplication.shared.canOpenURL(settingsUrl) {
                                    UIApplication.shared.open(settingsUrl)
                                }
                            }
                        }
                        
                    case .unknown:
                        break
                        
                    default:
                        break
                    }
                }
                
            case .view(.checkWatch):
                return .run { send in
                    let status = await watchConnectivityClient.checkWatchStatus()
                    await send(.core(.watchConnectivityStatusChange(status)))
                }
                
            case let .core(.openBluetoothFeature(bluetoothStatus)):
                state.destination = .bluetoothFeature(BluetoothFeature.State(bluetoothStatus: bluetoothStatus))
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

