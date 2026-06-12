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
        // Discovery info read response — odpalany po `peripheral.readValue(for:)`.
        // HR characteristic ma notify ale peripheral NIE wysyła notify update'ów,
        // więc tego callback'a nigdy dla HR nie dostaniemy.
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
}
