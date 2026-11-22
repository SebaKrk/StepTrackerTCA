//
//  CBPeripheralDelegate.swift
//  HealthHub
//
//  Created by Sebastian Sciuba on 02/09/2025.
//

@preconcurrency
import CoreBluetooth
import OSLog
import SharedModels

extension DefaultCentralManager: CBPeripheralDelegate {
    
    // MARK: - CBPeripheralDelegate Methods
    
    /// Called when the device finishes discovering its services.
    ///
    /// After connecting, this method receives the list of available BLE services.
    /// It then starts discovering the characteristics of the Heart Rate service.
    ///
    /// - Parameters:
    ///   - peripheral: The connected BLE device
    ///   - error: The error, if service discovery failed
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        let name = peripheral.name ?? "Unknown"
        Logger.bluetooth.debug("[Delegate] services discovered: \(name)")

        if let error = error {
            Logger.bluetooth.error("[Delegate] service discovery error: \(name) — \(error.localizedDescription)")
            Task {
                await WorkoutFileLogger.shared.log("[BLE-HR] service discovery FAILED: \(name) — \(error.localizedDescription)")
            }
            // A setup that ends without a HR subscription must still refresh the device lists.
            emitHRSensorPresence()
            return
        }

        guard let services = peripheral.services else {
            Logger.bluetooth.error("[Delegate] no services found: \(name)")
            emitHRSensorPresence()
            return
        }

        for service in services where service.uuid == Gatt.Service.heartRate {
            Logger.bluetooth.debug("[Delegate] HR service found — discovering characteristics")
            peripheral.discoverCharacteristics([Gatt.Characteristic.heartRateMeasurement], for: service)
        }

        if !services.contains(where: { $0.uuid == Gatt.Service.heartRate }) {
            emitHRSensorPresence()
        }
    }
    
    /// Called when the device finishes discovering the characteristics of one service.
    ///
    /// Once the Heart Rate service is found, this method receives its characteristics.
    /// It then subscribes to notifications of the Heart Rate Measurement characteristic.
    ///
    /// - Parameters:
    ///   - peripheral: The connected BLE device
    ///   - service: The service whose characteristics were discovered
    ///   - error: The error, if characteristic discovery failed
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        let name = peripheral.name ?? "Unknown"
        Logger.bluetooth.debug("[Delegate] characteristics discovered: \(service.uuid)")

        if let error = error {
            Logger.bluetooth.error("[Delegate] characteristic discovery error: \(name) — \(error.localizedDescription)")
            Task {
                await WorkoutFileLogger.shared.log("[BLE-HR] characteristic discovery FAILED: \(name) — \(error.localizedDescription)")
            }
            emitHRSensorPresence()
            return
        }

        guard let characteristics = service.characteristics else {
            Logger.bluetooth.error("[Delegate] no characteristics found: \(name)")
            emitHRSensorPresence()
            return
        }

        for characteristic in characteristics where characteristic.uuid == Gatt.Characteristic.heartRateMeasurement {
            Logger.bluetooth.debug("[Delegate] HR measurement characteristic found — subscribing")
            peripheral.setNotifyValue(true, for: characteristic)
        }
    }
    
    /// Called when the notification state of a characteristic changes.
    ///
    /// Confirms that the app subscribed to Heart Rate notifications.
    /// From here on the device sends data by itself, which HealthKit
    /// can receive and process during the workout session.
    ///
    /// - Parameters:
    ///   - peripheral: The connected BLE device
    ///   - characteristic: The characteristic whose notification state changed
    ///   - error: The error, if changing the notification state failed
    public func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        let name = peripheral.name ?? "Unknown"
        /// Session-file diagnostics: HR subscription success/failure — "connected
        /// but not subscribed" is a different failure class than no connection.
        if let error = error {
            Logger.bluetooth.error("[Delegate] HR subscribe FAILED: \(name) — \(error.localizedDescription)")
            Task {
                await WorkoutFileLogger.shared.log("[BLE-HR] subscribe FAILED: \(name) — \(error.localizedDescription)")
            }
            emitHRSensorPresence()
        } else {
            Logger.bluetooth.info("[Delegate] HR notifications subscribed: \(name)")
            /// HR service is confirmed now (discovered + subscribed), so
            /// `retrieveConnectedPeripherals(withServices:)` includes this sensor
            /// — emit presence HERE, not at `didConnect` (too early: the service
            /// is not yet discovered there, so the query returns empty → false).
            emitHRSensorPresence()
            Task {
                await WorkoutFileLogger.shared.log("[BLE-HR] subscribed to HR notifications: \(name)")
            }
        }
    }

    /// BLE-layer diagnostics: OUR subscription to heart-rate measurements.
    ///
    /// HealthKit has its own independent delivery — these values feed the log
    /// only: the first notification after a connect and a resume after >60 s of
    /// silence go to the session file. This resolves the key ambiguity of a
    /// strap outage: "the strap is SILENT" (no lines) vs "the strap is SENDING
    /// while HealthKit stalls" (lines present, yet `sensor STALE` persists).
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard characteristic.uuid == Gatt.Characteristic.heartRateMeasurement,
              error == nil,
              let data = characteristic.value, data.count >= 2 else { return }

        // BLE Heart Rate Measurement: flags bit 0 = value format (uint8 / uint16 LE).
        // Length is validated per format — a malformed packet from an external
        // device must not crash diagnostics-only code.
        let bytes = [UInt8](data)
        let isUInt16 = (bytes[0] & 0x01) != 0
        guard data.count >= (isUInt16 ? 3 : 2) else { return }
        let bpm: Int = isUInt16
            ? Int(bytes[1]) | (Int(bytes[2]) << 8)
            : Int(bytes[1])

        // Every parsed reading feeds the HR-fallback stream, independent of the
        // log-event bookkeeping below.
        emitStrapHRReading(bpm: bpm)

        guard let event = noteHRNotify(peripheral.identifier) else { return }
        let name = peripheral.name ?? "Unknown"
        Task {
            if event.isFirst {
                await WorkoutFileLogger.shared.log("[BLE-HR] notify STARTED: \(name) — \(bpm) bpm")
            } else if let gap = event.silenceGap {
                await WorkoutFileLogger.shared.log("[BLE-HR] notify RESUMED: \(name) — \(bpm) bpm (silent for \(Int(gap))s)")
            }
        }
    }
    
}
