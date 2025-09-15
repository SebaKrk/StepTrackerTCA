//
//  BluetoothFeature+Action.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 12/09/2025.
//

import CoreBluetooth
import ComposableArchitecture
import Foundation
import HealthHub

/// Implementation of `BluetoothFeature` action
extension BluetoothFeature {
   
   @CasePathable
   enum Action: ViewAction {
       
       // MARK: - Status Actions
       
       /// Aktualizuje status Bluetooth w aplikacji (ready/disabled/unauthorized/unknown)
       /// Wywoływane gdy system zmieni stan Bluetooth lub podczas inicjalizacji
       case bluetoothStatusChanged(BluetoothStatus)

       
       // MARK: - Scanning Actions
       
       /// Rozpoczyna fizyczne skanowanie BLE - wywołuje client.startScanning()
       /// Następuje po startScanningForDevices, poprzedza startListeningForDevices
       case scanningStarted
       
       /// Główna akcja inicjująca proces skanowania urządzeń
       /// Sprawdza warunki (czy już nie skanuje) i uruchamia sekwencję skanowania
       case startScanningForDevices
       
       /// Rozpoczyna nasłuchiwanie strumienia znalezionych urządzeń
       /// Tworzy AsyncStream i odbiera deviceDiscovered events
       case startListeningForDevices
       
       /// Zatrzymuje skanowanie i anuluje stream nasłuchiwania
       /// Wywołuje client.stopScanning() i cancel(id: "scanning")
       case scanningStopped
       
       /// Aktualizuje stan UI skanowania (pokazuje/ukrywa progress indicator)
       /// true = skanowanie aktywne, false = skanowanie zatrzymane
       case scanningStatusChanged(Bool)
       
       /// Dodaje nowo znalezione urządzenie do listy discoveredPeripherals
       /// Wywoływane przez stream z każdym wykrytym urządzeniem BLE
       case deviceDiscovered(CBPeripheral)
       
       // MARK: - Device Management Actions
       
       /// Aktualizuje listę urządzeń połączonych na poziomie systemu iOS
       /// Wywoływane przy inicjalizacji i po zmianach połączeń
       case systemConnectedDevicesChanged([CBPeripheral])
       
       /// Ustala urządzenie wybrane przez użytkownika jako aktywne
       /// nil = brak wybranego urządzenia, CBPeripheral = wybrane urządzenie
       case selectedDeviceChanged(CBPeripheral?)

       
       // MARK: - View Actions
       case view(View)
       
       enum View {
           
           /// Główny widok się pojawił - punkt inicjalizacji aplikacji
           case viewDidAppear
           
           /// Użytkownik zamyka ekran Bluetooth
           /// Zatrzymuje skanowanie i zamyka widok
           case closeButtonTapped
           
           /// Przełącza stan skanowania (start/stop)
           /// Sprawdza stan i wywołuje odpowiednie akcje skanowania
           case scanningButtonTapped
           
           /// Użytkownik wybiera urządzenie z listy
           /// Inicjuje połączenie i ustawia jako selectedDevice
           case deviceTapped(CBPeripheral)
           
           /// Użytkownik żąda rozłączenia konkretnego urządzenia
           /// Wywołuje client.disconnect(peripheral) i odświeża listę
           case disconnectButtonTapped(CBPeripheral)
           
           /// Przejście do ustawień Bluetooth (brak uprawnień)
           /// Otwiera App-Prefs:root=Bluetooth
           case unauthorizedButtonTapped
           
           /// Przejście do ustawień aplikacji (Bluetooth wyłączony)
           /// Otwiera ogólne ustawienia aplikacji
           case disabledButtonTaped
           
           /// Widok gotowy do użycia się pojawił (Bluetooth ready)
           /// Ładuje systemowe urządzenia i rozpoczyna skanowanie
           case readyViewDidAppear
       }
   }
    
}
