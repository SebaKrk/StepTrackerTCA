//
//  ConnectionEvent.swift
//  HealthHub
//
//  Created by Sebastian Sciuba on 05/09/2025.
//

@preconcurrency
import CoreBluetooth

public enum ConnectionEvent: Equatable, Sendable {
    case connecting(CBPeripheral)
    case connected(CBPeripheral)
    case disconnected(CBPeripheral, error: String?)
    case failedToConnect(CBPeripheral, error: String?)
}


extension CBPeripheral: @unchecked Sendable {}
