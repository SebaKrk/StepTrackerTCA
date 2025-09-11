//
//  ActivityPickerFeature.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 02/09/2025.
//

import CoreBluetooth
import ComposableArchitecture
import Foundation
import SharedModels
import HealthHub

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
               
               // Reaguj na zmiany statusu
               switch status {
               case .ready:
                   // Bluetooth gotowy - można automatycznie startować scan
                   if !state.isScanning {
                       return .run { send in
                           try await client.startScanning()
                           await send(.scanningStarted)
                       }
                   }
                   
               case .disabled:
                   // Bluetooth wyłączony - zatrzymaj skanowanie jeśli trwa
                   if state.isScanning {
                       return .merge(
                           .send(.scanningStatusChanged(false)),
                           .send(.discoveredPeripheralsCleared),
                           .run { send in
                               await client.stopScanning()
                           }
                       )
                   }
                   
               case .unauthorized:
                   // Brak uprawnień - zatrzymaj skanowanie i wyczyść listę
                   return .merge(
                       .send(.scanningStatusChanged(false)),
                       .send(.discoveredPeripheralsCleared)
                   )
                   
               case .unknown, .unsupported, .disconnected:
                   // Stany przejściowe lub błędy
                   break
               }
               return .none
               
               // MARK: - Scanning Actions
           case let .scanningStatusChanged(value):
               state.isScanning = value
               return .none
               
           case .scanningStarted:
               return .merge(
                   .send(.scanningStatusChanged(true)),
                   .run { send in
                       print("📡 Starting scanning stream")
                       // KLUCZOWA ZMIANA: Pobieramy NOWY stream za każdym razem
                       let devicesStream = await client.discoveredDevices()
                       
                       for await device in devicesStream {
                           print("📡 Stream yielded device: \(device.name ?? "Unknown")")
                           await send(.deviceDiscovered(device))
                       }
                       print("🔴 Scanning stream ENDED")
                   }
                   .cancellable(id: "scanning")
               )
               
           case .scanningStopped:
               print("⏹️ Scanning stopped")
               return .send(.scanningStatusChanged(false))
               
           case .discoveredPeripheralsCleared:
               state.discoveredPeripherals.removeAll()
               return .none
               
               // MARK: - Device Actions
           case let .deviceDiscovered(peripheral):
               // Dodajemy urządzenie do listy jeśli jeszcze go nie ma
               if !state.discoveredPeripherals.contains(where: { $0.identifier == peripheral.identifier }) {
                   state.discoveredPeripherals.append(peripheral)
                   print("📡 BluetoothFeature: Discovered NEW device: \(peripheral.name ?? "Unknown")")
               }
               return .none
               
               // MARK: - Connection Actions
           case let .connectedDeviceChanged(device):
               state.connectedDevice = device
               return .none
               
           case let .connectionStatusChanged(status):
               state.connectionStatus = status
               return .none
               
               // MARK: - View Actions
           case .view(.viewDidAppear):
               return .run { send in
                   print("🔍 BluetoothFeature: viewDidAppear - sprawdzam stan")
                   
                   let currentStatus = await client.getCurrentStatus()
                   print("🔍 BluetoothFeature: currentStatus = \(currentStatus)")
                   await send(.bluetoothStatusChanged(currentStatus))
                   
                   // 1. Sprawdź aplikacyjne połączenie
                   let connectedDevice = await client.connectedPeripheral()
                   print("🔍 BluetoothFeature: connectedDevice = \(connectedDevice?.name ?? "nil")")
                   
                   if let connectedDevice = connectedDevice {
                       print("🔍 BluetoothFeature: Znalazłem połączone urządzenie - aktualizuję UI")
                       await send(.connectedDeviceChanged(connectedDevice))
                       await send(.connectionStatusChanged("Connected to \(connectedDevice.name ?? "Unknown")"))
                   } else {
                       // 2. Sprawdź systemowe połączenia
                       let systemDevices = await client.getConnectedPeripherals()
                       print("🔍 BluetoothFeature: System devices: \(systemDevices.map { $0.name ?? "Unknown" })")
                       
                       if let systemDevice = systemDevices.first {
                           print("🔍 BluetoothFeature: Znalazłem systemowe urządzenie - aktualizuję UI")
                           await send(.connectedDeviceChanged(systemDevice))
                           await send(.connectionStatusChanged("System connected: \(systemDevice.name ?? "Unknown")"))
                       } else {
                           print("🔍 BluetoothFeature: Brak połączonego urządzenia")
                       }
                   }
               }
               
           case .view(.closeButtonTapped):
               return .merge(
                   .cancel(id: "scanning"),
                   .run { send in
                       await client.stopScanning()
                       await send(.scanningStopped)
                       await self.dismiss()
                   }
               )
               
           case .view(.scanningButtonTapped):
               if state.isScanning {
                   // Zatrzymaj skanowanie
                   return .merge(
                       .cancel(id: "scanning"),
                       .run { send in
                           await client.stopScanning()
                           await send(.scanningStopped)
                       }
                   )
               } else {
                   // Rozpocznij skanowanie (tylko jeśli Bluetooth gotowy)
                   guard state.bluetoothStatus == .ready else {
                       return .none
                   }
                   return .run { send in
                       try await client.startScanning()
                       await send(.scanningStarted)
                   }
               }

           case let .view(.deviceTapped(peripheral)):
               print("deviceTapped \(peripheral)")
               return .merge(
                   .send(.connectionStatusChanged("Connecting...")),
                   .send(.scanningStatusChanged(false)),
                   .cancel(id: "scanning"),
                   .run { send in
                       try await client.connect(peripheral)
                       
                       // Symulacja connected event (tymczasowo)
                       await send(.connectedDeviceChanged(peripheral))
                       await send(.connectionStatusChanged("Connected to \(peripheral.name ?? "Unknown")"))
                   }
               )
               
           case .view(.disconnectButtonTapped):
               return .run { send in
                   await client.disconnect()
                   await send(.connectedDeviceChanged(nil))
                   await send(.connectionStatusChanged("Disconnected"))
                   print("User disconnected device")
               }
           }
       }
   }
}

/// Implementation of `BluetoothFeature` action
extension BluetoothFeature {
   
   @CasePathable
   enum Action: ViewAction {
       
       // MARK: - Actions
       
       /// Aktualizuje stan Bluetooth w Feature (ready/disabled/unauthorized etc.)
       case bluetoothStatusChanged(BluetoothStatus)
       
       /// Rozpoczęcie skanowania urządzeń - uruchamia AsyncStream dla znalezionych urządzeń
       case scanningStarted
       
       /// Zakończenie skanowania urządzeń - zatrzymuje AsyncStream
       case scanningStopped
       
       /// Zmiana stanu skanowania (true/false) - aktualizuje UI
       case scanningStatusChanged(Bool)
       
       /// Znaleziono nowe urządzenie podczas skanowania - dodaje do listy
       case deviceDiscovered(CBPeripheral)
       
       /// Zmiana aktualnie połączonego urządzenia (nil = brak połączenia)
       case connectedDeviceChanged(CBPeripheral?)
       
       /// Wyczyść listę znalezionych urządzeń
       case discoveredPeripheralsCleared
       
       /// Aktualizacja statusu połączenia jako tekst dla UI
       case connectionStatusChanged(String)
       
       // MARK: - View Actions
       case view(View)
       
       enum View {
           /// Widok się pojawił - sprawdź status Bluetooth
           case viewDidAppear
           
           /// User nacisnął przycisk zamknięcia - zatrzymaj wszystko i zamknij
           case closeButtonTapped
           
           /// User nacisnął przycisk skanowania - start/stop scanning
           case scanningButtonTapped
           
           /// User nacisnął na urządzenie na liście - spróbuj się połączyć
           case deviceTapped(CBPeripheral)
           
           ///
           case disconnectButtonTapped
       }
   }
}

/// Implementation of `BluetoothFeature` state
extension BluetoothFeature {
   
   @ObservableState
   struct State {
       
       /// Aktualny status systemu Bluetooth (ready/disabled/unknown etc.)
       var bluetoothStatus: BluetoothStatus = .unknown
       
       /// Czy aktualnie skanuje urządzenia BLE
       var isScanning: Bool = false
       
       /// Lista wszystkich znalezionych urządzeń podczas skanowania
       var discoveredPeripherals: [CBPeripheral] = []
       
       /// Aktualnie połączone urządzenie (nil jeśli brak połączenia)
       var connectedDevice: CBPeripheral? = nil
       
       /// Status połączenia jako tekst do wyświetlenia w UI
       var connectionStatus: String = ""
       
       /// Computed property - lista dostępnych urządzeń (bez aktualnie połączonego)
       /// Używane do oddzielnego wyświetlania "Available" i "Connected" w UI
       var availableDevices: [CBPeripheral] {
           discoveredPeripherals.filter { device in
               device != connectedDevice
           }
       }
   }
}

// MARK: - Usunięte tymczasowo (będą dodawane osobno później):
// case connectionEventReceived(ConnectionEvent)
// connectionEvents stream handling
//import CoreBluetooth
//import ComposableArchitecture
//import Foundation
//import SharedModels
//import HealthHub
//
//@Reducer
//struct BluetoothFeature {
//   
//   // MARK: - Dependency
//   
//   @Dependency(\.dismiss) var dismiss
//   @Dependency(\.bluetoothClient) var client
//   
//   // MARK: - Reducer
//   
//   var body: some Reducer<State, Action> {
//       Reduce<State, Action> { state, action in
//           switch action {
//               
//               // MARK: - Status Actions
//           case let .bluetoothStatusChanged(status):
//               state.bluetoothStatus = status
//               
//               // Reaguj na zmiany statusu
//               switch status {
//               case .ready:
//                   // Bluetooth gotowy - można automatycznie startować scan
//                   if !state.isScanning {
//                       return .run { send in
//                           try await client.startScanning()
//                           await send(.scanningStarted)
//                       }
//                   }
//                   
//               case .disabled:
//                   // Bluetooth wyłączony - zatrzymaj skanowanie jeśli trwa
//                   if state.isScanning {
//                       return .merge(
//                           .send(.scanningStatusChanged(false)),
//                           .send(.discoveredPeripheralsCleared),
//                           .run { send in
//                               await client.stopScanning()
//                           }
//                       )
//                   }
//                   
//               case .unauthorized:
//                   // Brak uprawnień - zatrzymaj skanowanie i wyczyść listę
//                   return .merge(
//                       .send(.scanningStatusChanged(false)),
//                       .send(.discoveredPeripheralsCleared)
//                   )
//                   
//               case .unknown, .unsupported, .disconnected:
//                   // Stany przejściowe lub błędy
//                   break
//               }
//               return .none
//               
//               // MARK: - Scanning Actions
//           case let .scanningStatusChanged(value):
//               state.isScanning = value
//               return .none
//               
//           case .scanningStarted:
//               return .merge(
//                   .send(.scanningStatusChanged(true)),
//                   .run { send in
//                       print("📡 Starting scanning stream")
//                       for await device in await client.discoveredDevices() {
//                           print("📡 Stream yielded device: \(device.name ?? "Unknown")")
//                           await send(.deviceDiscovered(device))
//                       }
//                       print("🔴 Scanning stream ENDED")
//                   }
//                   .cancellable(id: "scanning")
//               )
//               
//           case .scanningStopped:
//               print("⏹️ Scanning stopped")
//               return .send(.scanningStatusChanged(false))
//               
//           case .discoveredPeripheralsCleared:
//               state.discoveredPeripherals.removeAll()
//               return .none
//               
//               // MARK: - Device Actions
//           case let .deviceDiscovered(peripheral):
//               // Dodajemy urządzenie do listy jeśli jeszcze go nie ma
//               if !state.discoveredPeripherals.contains(where: { $0.identifier == peripheral.identifier }) {
//                   state.discoveredPeripherals.append(peripheral)
//                   print("📡 BluetoothFeature: Discovered NEW device: \(peripheral.name ?? "Unknown")")
//               }
//               return .none
//               
//               // MARK: - Connection Actions
//           case let .connectedDeviceChanged(device):
//               state.connectedDevice = device
//               return .none
//               
//           case let .connectionStatusChanged(status):
//               state.connectionStatus = status
//               return .none
//               
//           case .connectionEventReceived(let event):
//               switch event {
//               case .connecting(let peripheral):
//                   let status = "Connecting to \(peripheral.name ?? "Unknown")..."
//                   return .send(.connectionStatusChanged(status))
//                   
//               case .connected(let peripheral):
//                   let status = "Connected to \(peripheral.name ?? "Unknown")"
//                   return .merge(
//                       .send(.connectedDeviceChanged(peripheral)),
//                       .send(.connectionStatusChanged(status)),
//                       .cancel(id: "scanning"),
//                       .cancel(id: "connectionEvents"),
//                       .run { send in
//                           await client.stopScanning()
//                           //await self.dismiss()
//                       }
//                   )
//                   
//               case .disconnected(let peripheral, let error):
//                   let errorMsg = error != nil ? " (\(error!))" : ""
//                   let status = "Disconnected from \(peripheral.name ?? "Unknown")\(errorMsg)"
//                   return .merge(
//                       .send(.connectedDeviceChanged(nil)),
//                       .send(.connectionStatusChanged(status))
//                   )
//                   
//               case .failedToConnect(let peripheral, let error):
//                   let errorMsg = error ?? "Unknown error"
//                   let status = "Failed to connect to \(peripheral.name ?? "Unknown"): \(errorMsg)"
//                   return .merge(
//                       .send(.connectedDeviceChanged(nil)),
//                       .send(.connectionStatusChanged(status))
//                   )
//               }
//               
//               // MARK: - View Actions
//           case .view(.viewDidAppear):
//               // Sprawdź status Bluetooth tylko raz na żądanie
//               return .run { send in
//                   let currentStatus = await client.getCurrentStatus()
//                   await send(.bluetoothStatusChanged(currentStatus))
//               }
//               
//           case .view(.closeButtonTapped):
//               return .merge(
//                   .cancel(id: "scanning"),
//                   .cancel(id: "connectionEvents"),
//                   .run { send in
//                       await client.stopScanning()
//                       await send(.scanningStopped)
//                       await self.dismiss()
//                   }
//               )
//               
//           case .view(.scanningButtonTapped):
//               if state.isScanning {
//                   // Zatrzymaj skanowanie
//                   return .merge(
//                       .cancel(id: "scanning"),
//                       .run { send in
//                           await client.stopScanning()
//                           await send(.scanningStopped)
//                       }
//                   )
//               } else {
//                   // Rozpocznij skanowanie (tylko jeśli Bluetooth gotowy)
//                   guard state.bluetoothStatus == .ready else {
//                       return .none
//                   }
//                   return .run { send in
//                       try await client.startScanning()
//                       await send(.scanningStarted)
//                   }
//               }
//
//           case let .view(.deviceTapped(peripheral)):
//               print("deviceTapped \(peripheral)")
//               return .merge(
//                   .send(.connectionStatusChanged("Connecting...")),
//                   .send(.scanningStatusChanged(false)),
//                   .cancel(id: "scanning"),
//                   .run { send in
//                       try await client.connect(peripheral)
//                   },
//                   .run { send in
//                       for await event in await client.connectionEvents() {
//                           await send(.connectionEventReceived(event))
//                       }
//                   }
//                   .cancellable(id: "connectionEvents")
//               )
//           }
//       }
//   }
//}
//
///// Implementation of `BluetoothFeature` action
//extension BluetoothFeature {
//   
//   @CasePathable
//   enum Action: ViewAction {
//       
//       // MARK: - Actions
//       
//       /// Aktualizuje stan Bluetooth w Feature (ready/disabled/unauthorized etc.)
//       case bluetoothStatusChanged(BluetoothStatus)
//       
//       /// Rozpoczęcie skanowania urządzeń - uruchamia AsyncStream dla znalezionych urządzeń
//       case scanningStarted
//       
//       /// Zakończenie skanowania urządzeń - zatrzymuje AsyncStream
//       case scanningStopped
//       
//       /// Zmiana stanu skanowania (true/false) - aktualizuje UI
//       case scanningStatusChanged(Bool)
//       
//       /// Znaleziono nowe urządzenie podczas skanowania - dodaje do listy
//       case deviceDiscovered(CBPeripheral)
//       
//       /// Zmiana aktualnie połączonego urządzenia (nil = brak połączenia)
//       case connectedDeviceChanged(CBPeripheral?)
//       
//       /// Otrzymano event połączenia z urządzeniem (connecting/connected/disconnected)
//       case connectionEventReceived(ConnectionEvent)
//       
//       /// Wyczyść listę znalezionych urządzeń
//       case discoveredPeripheralsCleared
//       
//       /// Aktualizacja statusu połączenia jako tekst dla UI
//       case connectionStatusChanged(String)
//       
//       // MARK: - View Actions
//       case view(View)
//       
//       enum View {
//           /// Widok się pojawił - sprawdź status Bluetooth
//           case viewDidAppear
//           
//           /// User nacisnął przycisk zamknięcia - zatrzymaj wszystko i zamknij
//           case closeButtonTapped
//           
//           /// User nacisnął przycisk skanowania - start/stop scanning
//           case scanningButtonTapped
//           
//           /// User nacisnął na urządzenie na liście - spróbuj się połączyć
//           case deviceTapped(CBPeripheral)
//       }
//   }
//}
//
///// Implementation of `BluetoothFeature` state
//extension BluetoothFeature {
//   
//   @ObservableState
//   struct State {
//       
//       /// Aktualny status systemu Bluetooth (ready/disabled/unknown etc.)
//       var bluetoothStatus: BluetoothStatus = .unknown
//       
//       /// Czy aktualnie skanuje urządzenia BLE
//       var isScanning: Bool = false
//       
//       /// Lista wszystkich znalezionych urządzeń podczas skanowania
//       var discoveredPeripherals: [CBPeripheral] = []
//       
//       /// Aktualnie połączone urządzenie (nil jeśli brak połączenia)
//       var connectedDevice: CBPeripheral? = nil
//       
//       /// Status połączenia jako tekst do wyświetlenia w UI
//       var connectionStatus: String = ""
//       
//       /// Computed property - lista dostępnych urządzeń (bez aktualnie połączonego)
//       /// Używane do oddzielnego wyświetlania "Available" i "Connected" w UI
//       var availableDevices: [CBPeripheral] {
//           discoveredPeripherals.filter { device in
//               device != connectedDevice
//           }
//       }
//   }
//}
//
