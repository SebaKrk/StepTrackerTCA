//
//  CBCentralManagerDelegate.swift
//  HealthHub
//
//  Created by Sebastian Sciuba on 02/09/2025.
//

@preconcurrency
import CoreBluetooth

extension DefaultCentralManager: CBCentralManagerDelegate {
   
   /// Wywoływane gdy stan Bluetooth się zmieni
   public func centralManagerDidUpdateState(_ central: CBCentralManager) {
       print("🔄 Bluetooth state changed to: \(central.state)")
       
       Task {
           await updateStatusFromCBState(central.state)
       }
   }
   
   /// Wywoływane gdy znajdziemy nowe urządzenie podczas skanowania
   public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
       
       let deviceName = peripheral.name ?? "Unknown"
       print("📡 Discovered device: \(deviceName) (RSSI: \(RSSI))")
       
       Task {
           await scanActor.yieldDevice(peripheral)
       }
   }
   
   /// Wywoływane gdy udało się połączyć z urządzeniem
   public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
       print("✅ Connected to: \(peripheral.name ?? "Unknown")")
       
       peripheral.delegate = self
       peripheral.discoverServices([Gatt.Service.heartRate, Gatt.Service.weightScale])
       print("🔍 Starting service discovery...")
   }
   
   /// Wywoływane gdy nie udało się połączyć z urządzeniem
   public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
       print("❌ Failed to connect to: \(peripheral.name ?? "Unknown")")
       if let error = error {
           print("   Error: \(error.localizedDescription)")
       }
   }
   
   /// Wywoływane gdy urządzenie się rozłączyło
   public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
       print("📵 Disconnected from: \(peripheral.name ?? "Unknown")")
       
       if let error = error {
           print("   Disconnect error: \(error.localizedDescription)")
       }
   }
}
