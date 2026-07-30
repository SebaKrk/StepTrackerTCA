//
//  BluetoothFeature.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 02/09/2025.
//

import CoreBluetooth
import ComposableArchitecture
import Foundation
import SharedModels
import HealthHub
import SwiftUI

@Reducer
struct BluetoothFeature {
   
   // MARK: - Dependency
   
   @Dependency(\.dismiss) var dismiss
   @Dependency(\.bluetoothClient) var client
   
   // MARK: - Reducer
   
   var body: some Reducer<State, Action> {
       Reduce<State, Action> { state, action in
           switch action {
               
               // MARK: - Status Actions
               
           case let .bluetoothStatusChanged(status):
               state.bluetoothStatus = status
               return .none
               
           case let .scanningStatusChanged(status):
               state.isScanning = status
               return .none
               
           case .systemConnectedDevicesChanged(let devices):
               state.systemConnectedDevices = devices
               return .none
               
           case .selectedDeviceChanged(let device):
               state.selectedDevice = device
               return .none

           case .startConnectionMonitoring:
               return .run { send in
                   for await _ in await client.connectedHRSensorPresence() {
                       let systemDevices = await client.getConnectedPeripherals()
                       await send(.systemConnectedDevicesChanged(systemDevices))
                   }
               }
               .cancellable(id: "connectionMonitoring")
               
           case .startScanningForDevices:
               guard !state.isScanning else {
                   print("⚠️ Already scanning - ignoring request")
                   return .none
               }
               
               return .merge(
                   .send(.scanningStatusChanged(true)),
                   .send(.scanningStarted)
               )

           case .scanningStarted:
               return .merge(
                   .run { send in
                       try await client.startScanning()
                   },
                   .send(.startListeningForDevices)
               )

           case .startListeningForDevices:
               return .run { send in
                   let devicesStream = await client.discoveredDevices()
                   
                   for await device in devicesStream {
                       await send(.deviceDiscovered(device))
                   }
                   print("🔴 Scanning stream ENDED")
               }
               .cancellable(id: "scanning")
               
           case .scanningStopped:
               return .merge(
                   .send(.scanningStatusChanged(false)),
                   .cancel(id: "scanning"),
                   .run { _ in await client.stopScanning() }
               )
               
           case let .deviceDiscovered(peripheral):
               if !state.discoveredPeripherals.contains(where: { $0.identifier == peripheral.identifier }) {
                   state.discoveredPeripherals.append(peripheral)
               }
               return .none
               
               // MARK: - View Actions
       
           case .view(.viewDidAppear):
               return .none
               
           case .view(.readyViewDidAppear):
               return .merge(
                   .run { send in
                       let systemDevices = await client.getConnectedPeripherals()
                       await send(.systemConnectedDevicesChanged(systemDevices))

                       for device in systemDevices {
                           await send(.deviceDiscovered(device))
                       }

                       await send(.startScanningForDevices)
                   },
                   .send(.startConnectionMonitoring)
               )

           case .view(.unauthorizedButtonTapped):
               if let settingsUrl = URL(string: "App-Prefs:root=Bluetooth") {
                   UIApplication.shared.open(settingsUrl)
               }
               return .none
               
           case .view(.disabledButtonTaped):
               if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                   UIApplication.shared.open(settingsUrl)
               }
               return .none

           case .view(.closeButtonTapped):
               return .merge(
                   .cancel(id: "connectionMonitoring"),
                   .run { send in
                       await send(.scanningStopped)
                       await self.dismiss()
                   }
               )

           case let .view(.deviceTapped(peripheral)):
               return .run { send in
                   try await client.connect(peripheral)
                   await send(.selectedDeviceChanged(peripheral))
                   await send(.scanningStopped)
                   // The system-connected list refreshes via `startConnectionMonitoring`
                   // when CoreBluetooth reports the connect — no fixed delay needed.
               }

           case let .view(.disconnectButtonTapped(peripheral)):
               return .run { send in
                   await client.disconnect(peripheral)
                   // The list refreshes via `startConnectionMonitoring` on the
                   // CoreBluetooth disconnect event — no fixed delay needed.
               }
               
           case .view(.scanningButtonTapped):
               if state.isScanning {
                   return .send(.scanningStopped)
               } else {
                   guard state.bluetoothStatus == .ready else {
                       return .none
                   }
                   return .send(.startScanningForDevices)
               }
           }
       }
   }
    
}
