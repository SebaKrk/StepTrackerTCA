//
//  CBPeripheralDelegate.swift
//  HealthHub
//
//  Created by Sebastian Sciuba on 02/09/2025.
//

@preconcurrency
import CoreBluetooth

extension DefaultCentralManager: CBPeripheralDelegate {
    
    // MARK: - CBPeripheralDelegate Methods
    
    /// Wywoływana gdy urządzenie zakończy proces odkrywania serwisów
    ///
    /// Po połączeniu z urządzeniem, ta metoda otrzymuje listę dostępnych serwisów BLE.
    /// Następnie rozpoczyna odkrywanie charakterystyk dla serwisu Heart Rate.
    ///
    /// - Parameters:
    ///   - peripheral: Połączone urządzenie BLE
    ///   - error: Błąd jeśli wystąpił podczas odkrywania serwisów
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        print("🔍 Services discovered for \(peripheral.name ?? "Unknown")")
        
        if let error = error {
            print("❌ Service discovery error: \(error.localizedDescription)")
            return
        }
        
        guard let services = peripheral.services else {
            print("❌ No services found")
            return
        }
        
        for service in services {
            print("🔍 Found service: \(service.uuid)")
            if service.uuid == Gatt.Service.heartRate {
                print("💓 Heart Rate service found - discovering characteristics...")
                peripheral.discoverCharacteristics([Gatt.Characteristic.heartRateMeasurement], for: service)
            }
        }
    }
    
    /// Wywoływana gdy urządzenie zakończy proces odkrywania charakterystyk dla konkretnego serwisu
    ///
    /// Po znalezieniu serwisu Heart Rate, ta metoda otrzymuje listę jego charakterystyk.
    /// Następnie subskrybuje notyfikacje dla charakterystyki Heart Rate Measurement.
    ///
    /// - Parameters:
    ///   - peripheral: Połączone urządzenie BLE
    ///   - service: Serwis dla którego odkryto charakterystyki
    ///   - error: Błąd jeśli wystąpił podczas odkrywania charakterystyk
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        print("🔍 Characteristics discovered for service: \(service.uuid)")
        
        if let error = error {
            print("❌ Characteristic discovery error: \(error.localizedDescription)")
            return
        }
        
        guard let characteristics = service.characteristics else {
            print("❌ No characteristics found")
            return
        }
        
        for characteristic in characteristics {
            print("🔍 Found characteristic: \(characteristic.uuid)")
            if characteristic.uuid == Gatt.Characteristic.heartRateMeasurement {
                print("💓 Heart Rate Measurement found - subscribing...")
                peripheral.setNotifyValue(true, for: characteristic)
            }
        }
    }
    
    /// Wywoływana gdy zmieni się stan subskrypcji notyfikacji dla charakterystyki
    ///
    /// Potwierdza że aplikacja pomyślnie zasubskrybowała notyfikacje Heart Rate.
    /// Po tym momencie urządzenie będzie wysyłać dane automatycznie, które HealthKit
    /// będzie mógł odbierać i przetwarzać podczas sesji treningowej.
    ///
    /// - Parameters:
    ///   - peripheral: Połączone urządzenie BLE
    ///   - characteristic: Charakterystyka dla której zmienił się stan notyfikacji
    ///   - error: Błąd jeśli wystąpił podczas zmiany stanu notyfikacji
    public func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        print("📡 Notification state updated for: \(characteristic.uuid)")
        
        if let error = error {
            print("❌ Notification error: \(error.localizedDescription)")
        } else {
            print("✅ Successfully subscribed to heart rate notifications!")
            print("💓 Connection is now stable - device won't timeout")
        }
    }
    
    /// Wywoływana gdy urządzenie wysyła nowe dane przez charakterystykę
    ///
    /// **Uwaga**: Ta metoda służy tylko do potwierdzenia połączenia z urządzeniem.
    /// Rzeczywiste dane heart rate są automatycznie zbierane przez HealthKit
    /// podczas sesji treningowej w WorkoutManager.
    ///
    /// **Flow danych:**
    /// 1. Bluetooth łączy się z urządzeniem i subskrybuje notyfikacje
    /// 2. Ta metoda otrzymuje surowe dane (tylko dla potwierdzenia połączenia)
    /// 3. HealthKit automatycznie odbiera te same dane i przetwarza je
    /// 4. Przetworzone dane trafiają do WorkoutManager przez HKLiveWorkoutBuilder
    ///
    /// - Parameters:
    ///   - peripheral: Urządzenie które wysłało dane
    ///   - characteristic: Charakterystyka która otrzymała nowe dane
    ///   - error: Opcjonalny błąd jeśli wystąpił podczas odbierania danych
//    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
//        if characteristic.uuid == Gatt.Characteristic.heartRateMeasurement {
//            guard let data = characteristic.value, data.count >= 2 else { return }
//            
//            let bytes = [UInt8](data)
//            let heartRate = Int(bytes[1])
//            
//            print("💓 peripheral didUpdateValueFor -> Heart Rate: \(heartRate) BPM")
//        }
//    }
}
