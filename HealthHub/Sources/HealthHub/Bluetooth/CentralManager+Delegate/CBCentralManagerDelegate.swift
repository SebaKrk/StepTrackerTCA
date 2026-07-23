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
       /// When Bluetooth becomes ready, an already-connected strap fires no
       /// `didConnect` — recompute presence so a picker that subscribed before
       /// power-on still reflects the truth.
       if central.state == .poweredOn {
           emitHRSensorPresence()
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
       let name = peripheral.name ?? "Unknown"
       Logger.bluetooth.info("[Delegate] connected: \(name)")
       peripheral.delegate = self
       peripheral.discoverServices([Gatt.Service.heartRate, Gatt.Service.weightScale])
       /// Session-file diagnostics: connect + real reconnect latency — the
       /// "RECONNECTED after Xs" line measures how fast the pending connect
       /// catches the strap once it is back in range.
       let dropInterval = takeDropInterval(peripheral.identifier)
       /// Held strap (re)connected — clear any pending disconnect reason so the
       /// host log shows "sensor recovered", not a stale drop cause.
       if isHeldPeripheral(peripheral.identifier) {
           emitHRSensorConnectionReason(nil)
       }
       // Presence is NOT emitted here: at `didConnect` the services are not yet
       // discovered, so `retrieveConnectedPeripherals(withServices:)` returns
       // empty. It is emitted once the HR characteristic is subscribed (see
       // `didUpdateNotificationStateFor`).
       Task {
           if let dropInterval {
               await WorkoutFileLogger.shared.log("[BLE-HR] RECONNECTED: \(name) after \(Int(dropInterval))s")
           } else {
               await WorkoutFileLogger.shared.log("[BLE-HR] connected: \(name)")
           }
       }
   }

   /// Wywoływane gdy nie udało się połączyć z urządzeniem
   public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
       let name = peripheral.name ?? "Unknown"
       let reason = (error as NSError?).map { "\($0.domain)#\($0.code): \($0.localizedDescription)" } ?? "no error info"
       Logger.bluetooth.error("[Delegate] failToConnect: \(name) — \(reason)")
       /// A failed connect can change presence (e.g. the only sensor never linked).
       emitHRSensorPresence()
       Task {
           await WorkoutFileLogger.shared.log("[BLE-HR] connect FAILED: \(name) — \(reason)")
       }
   }

   /// Wywoływane gdy urządzenie się rozłączyło
   public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
       let name = peripheral.name ?? "Unknown"
       /// The CoreBluetooth error CODE names the cause:
       /// CBErrorDomain#6 = connection timed out (range/signal),
       /// CBErrorDomain#7 = peripheral disconnected (the strap dropped the link
       /// itself — battery/firmware), no error = disconnect we requested.
       let reason = (error as NSError?).map { "\($0.domain)#\($0.code): \($0.localizedDescription)" } ?? "clean (requested)"
       if error != nil {
           Logger.bluetooth.error("[Delegate] disconnected: \(name) — \(reason)")
       } else {
           Logger.bluetooth.info("[Delegate] disconnected: \(name)")
       }
       /// Map the CoreBluetooth error to a domain reason and publish it — but only
       /// for a HELD strap (the workout sensor). `releaseHRSensorConnections` clears
       /// the hold BEFORE cancelling, so the clean end-of-workout disconnect arrives
       /// un-held and is not reported as a fault.
       if isHeldPeripheral(peripheral.identifier) {
           let nsError = error as NSError?
           let sensorReason: SensorDisconnectReason?
           if nsError == nil {
               sensorReason = nil                       // clean, app-requested
           } else if nsError?.domain == CBError.errorDomain {
               switch nsError?.code {
               case CBError.Code.connectionTimeout.rawValue: sensorReason = .outOfRange
               case CBError.Code.peripheralDisconnected.rawValue: sensorReason = .deviceOff
               default: sensorReason = .other
               }
           } else {
               sensorReason = .other                    // non-CoreBluetooth error domain
           }
           emitHRSensorConnectionReason(sensorReason)
       }
       noteDrop(peripheral.identifier)
       /// Live presence for the pre-workout device picker (the disconnected
       /// peripheral is already excluded from `retrieveConnectedPeripherals`).
       emitHRSensorPresence()
       /// EXPERIMENT (IOS-00100-D): czujnik przytrzymany na czas treningu dostaje
       /// natychmiastowy pending connect — bez timeoutu, ŻADNYCH watchdogów
       /// (wzorzec known-host reconnect z GymRoom). System połączy od razu, gdy
       /// pasek wróci w zasięg — bez czekania na wewnętrzny retry HealthKit.
       let isHeld = isHeldPeripheral(peripheral.identifier)
       if isHeld {
           central.connect(peripheral)
           Logger.bluetooth.info("[Connection] held sensor dropped — pending reconnect issued: \(name)")
       }
       Task {
           await WorkoutFileLogger.shared.log(
               "[BLE-HR] DISCONNECTED: \(name) — \(reason)\(isHeld ? " → pending reconnect issued" : "")"
           )
       }
   }
}
