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
   @Dependency(\.continuousClock) var clock

   // MARK: - Cancellation

   nonisolated enum CancelID: Hashable, Sendable {

       /// The pending connect attempt and its timeout.
       case connecting
   }

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
               // The pending pick is settled once the system lists it or CoreBluetooth stopped connecting.
               guard let selected = state.selectedDevice,
                     state.isConnected(selected) || selected.state != .connecting
               else { return .none }
               state.selectedDevice = nil
               return .cancel(id: CancelID.connecting)

           case let .connectionAttemptTimedOut(id):
               guard let selected = state.selectedDevice, selected.identifier == id else { return .none }
               // Cleared here, not from the effect, so a newer pick made meanwhile is never wiped.
               state.selectedDevice = nil
               return .run { send in
                   // The list may be stale, so ask the system before giving up on the device.
                   let devices = await client.getConnectedPeripherals()
                   if !devices.contains(where: { $0.identifier == id }) {
                       await client.disconnect(selected)
                   }
                   await send(.systemConnectedDevicesChanged(devices))
               }
               
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
               .cancellable(id: "connectionMonitoring", cancelInFlight: true)

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
                   // A scan that ends on its own (a connect stops it) must clear the indicator too.
                   await send(.scanningStatusChanged(false))
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
               // A device that is listed by the system and linked here has nothing left to connect.
               guard !(state.isConnected(peripheral) && peripheral.state == .connected) else { return .none }
               let abandoned = state.selectedDevice.flatMap { $0.identifier == peripheral.identifier ? nil : $0 }
               // Cleared now, so the abandoned device's disconnect event finds nothing to settle.
               state.selectedDevice = nil
               return .run { send in
                   if let abandoned {
                       await client.disconnect(abandoned)
                   }
                   try Task.checkCancellation()
                   try await client.connect(peripheral)
                   // Set after the connect is issued, so the peripheral already reports `.connecting`.
                   await send(.selectedDeviceChanged(peripheral))
                   await send(.scanningStopped)
                   // CoreBluetooth never gives up on a connect by itself.
                   try await clock.sleep(for: .seconds(15))
                   await send(.connectionAttemptTimedOut(peripheral.identifier))
               }
               .cancellable(id: CancelID.connecting, cancelInFlight: true)

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
