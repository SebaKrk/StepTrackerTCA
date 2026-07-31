//
//  PeerMirrorBLEPeerSession+CBPeripheralDelegate.swift
//  HealthHub
//
//  Created by Sebastian Ściuba on 2026-05-25.
//

import CoreBluetooth
import Foundation
import OSLog
import SharedModels

extension PeerMirrorBLEPeerSession: CBPeripheralDelegate {

    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error {
            Self.logger.error("Service discovery failed: \(error.localizedDescription, privacy: .public)")
            return
        }
        guard let gymService = peripheral.services?.first(
            where: { $0.uuid == BLEServiceConstants.gymRoomServiceUUID }
        ) else {
            Self.logger.error("GymRoom service not found on peripheral")
            return
        }
        peripheral.discoverCharacteristics(
            [BLEServiceConstants.hrStreamCharacteristicUUID,
             BLEServiceConstants.discoveryInfoCharacteristicUUID],
            for: gymService
        )
    }

    public func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverCharacteristicsFor service: CBService,
        error: Error?
    ) {
        if let error {
            Self.logger.error(
                "Characteristic discovery failed: \(error.localizedDescription, privacy: .public) — cancelling connection to trigger reconnect"
            )
            centralManager.cancelPeripheralConnection(peripheral)
            return
        }
        guard let hr = service.characteristics?.first(
            where: { $0.uuid == BLEServiceConstants.hrStreamCharacteristicUUID }
        ) else {
            Self.logger.error("HR characteristic not found — cancelling connection to trigger reconnect")
            centralManager.cancelPeripheralConnection(peripheral)
            return
        }
        hrCharacteristic = hr

        // Subscribe (presence signaling do peripheral via `didSubscribeTo` callback).
        // Peripheral nie wysyła żadnych notify update'ów — to tylko keep-alive marker.
        peripheral.setNotifyValue(true, for: hr)
        Self.logger.info("Subscribed to HR characteristic — reading discovery info for displayName")

        // Read discoveryInfo żeby pozyskać iPad displayName używany jako nick.
        // `.connected` emit JEST PRZENIESIONY do `didUpdateValueFor` — czeka na prawdziwy nick.
        if let discoveryInfo = service.characteristics?.first(
            where: { $0.uuid == BLEServiceConstants.discoveryInfoCharacteristicUUID }
        ) {
            peripheral.readValue(for: discoveryInfo)
        } else {
            // Fallback: discoveryInfo nie znaleziony — emit żeby reducer nie zwisł w .searching.
            // `deviceID` to BLE-level identifier iPada (nie stable per-install, ale peer ignoruje
            // payload — używa tylko sygnału `.connected` żeby przejść do phase `.connected`).
            Self.logger.warning("Discovery info characteristic not found — emitting with empty nick")
            onPeerEvent(.connected(deviceID: peripheral.identifier, nick: ""))
        }
    }

    public func peripheral(
        _ peripheral: CBPeripheral,
        didUpdateValueFor characteristic: CBCharacteristic,
        error: Error?
    ) {
        // HR characteristic notify — host→peer. Trzy typy rozróżniane prefiksem:
        //  - 1 bajt 0xFF          → class ended sentinel
        //  - prefiks 0xFE + JSON  → per-device recap (wynik zajęć)
        //  - inaczej (JSON `{`…)  → n/d (peer nie odbiera HR-JSON, host go nie notify'uje)
        if characteristic.uuid == BLEServiceConstants.hrStreamCharacteristicUUID {
            guard let value = characteristic.value, let first = value.first else { return }
            if value.count == 1, first == 0xFF {
                Self.logger.info("Class ended signal received from host")
                onPeerEvent(.classEnded)
                return
            }
            if first == 0xFE {
                guard let payload = try? JSONDecoder().decode(ClassRecapPayload.self, from: value.dropFirst())
                else {
                    Self.logger.error("Recap payload decode failed")
                    return
                }
                Self.logger.info("Recap received from host — place=\(payload.place, privacy: .public)")
                onPeerEvent(.recapReceived(payload))
                return
            }
            return
        }

        // Discovery info read response — odpalany po `peripheral.readValue(for:)`.
        guard characteristic.uuid == BLEServiceConstants.discoveryInfoCharacteristicUUID else {
            return
        }

        if let error {
            Self.logger.error(
                "Discovery info read failed: \(error.localizedDescription, privacy: .public) — empty nick fallback"
            )
            onPeerEvent(.connected(deviceID: peripheral.identifier, nick: ""))
            return
        }

        let displayName = characteristic.value
            .flatMap { String(data: $0, encoding: .utf8) }
            ?? peripheral.identifier.uuidString
        onPeerEvent(.connected(deviceID: peripheral.identifier, nick: displayName))
        Self.logger.info("Discovery info read: iPad displayName=\(displayName, privacy: .public)")
    }

    public func peripheral(
        _ peripheral: CBPeripheral,
        didUpdateNotificationStateFor characteristic: CBCharacteristic,
        error: Error?
    ) {
        if let error {
            Self.logger.error(
                "Notify state error: \(error.localizedDescription, privacy: .public)"
            )
        }
    }

    /// Fires only for `.withResponse` writes — today that is the goodbye alone.
    public func peripheral(
        _ peripheral: CBPeripheral,
        didWriteValueFor characteristic: CBCharacteristic,
        error: Error?
    ) {
        if let error {
            Self.logger.error("Goodbye write failed: \(error.localizedDescription, privacy: .public)")
        }
        resumeGoodbye(acked: error == nil, note: error?.localizedDescription ?? "write error")
    }
}
