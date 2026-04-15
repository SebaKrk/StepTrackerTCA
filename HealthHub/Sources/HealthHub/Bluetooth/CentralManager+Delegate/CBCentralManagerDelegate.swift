//
//  CBCentralManagerDelegate.swift
//  HealthHub
//
//  Created by Sebastian Sciuba on 02/09/2025.
//

@preconcurrency
import CoreBluetooth
import OSLog
import SharedModels

extension DefaultCentralManager: CBCentralManagerDelegate {
   
   /// Wywoływane gdy stan Bluetooth się zmieni
   public func centralManagerDidUpdateState(_ central: CBCentralManager) {
       Task {
           await updateStatusFromCBState(central.state)
       }
   }

   /// Wywoływane gdy znajdziemy nowe urządzenie podczas skanowania
   public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
       Logger.bluetooth.debug("[Delegate] discovered: \(peripheral.name ?? "Unknown") RSSI=\(RSSI)")
       Task {
           await scanActor.yieldDevice(peripheral)
       }
   }

   /// Wywoływane gdy udało się połączyć z urządzeniem
   public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
       Logger.bluetooth.info("[Delegate] connected: \(peripheral.name ?? "Unknown")")
       peripheral.delegate = self
       peripheral.discoverServices([Gatt.Service.heartRate, Gatt.Service.weightScale])
   }

   /// Wywoływane gdy nie udało się połączyć z urządzeniem
   public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
       if let error = error {
           Logger.bluetooth.error("[Delegate] failToConnect: \(peripheral.name ?? "Unknown") — \(error.localizedDescription)")
       } else {
           Logger.bluetooth.error("[Delegate] failToConnect: \(peripheral.name ?? "Unknown")")
       }
   }

   /// Wywoływane gdy urządzenie się rozłączyło
   public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
       if let error = error {
           Logger.bluetooth.error("[Delegate] disconnected: \(peripheral.name ?? "Unknown") — \(error.localizedDescription)")
       } else {
           Logger.bluetooth.info("[Delegate] disconnected: \(peripheral.name ?? "Unknown")")
       }
   }
}
