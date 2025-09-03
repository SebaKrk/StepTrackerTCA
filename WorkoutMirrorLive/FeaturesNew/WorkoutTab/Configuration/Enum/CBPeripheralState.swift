//
//  CBPeripheralState.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 03/09/2025.
//

import CoreBluetooth

public enum CBPeripheralState: Int {
    case disconnected = 0    // Rozłączone
    case connecting = 1      // Łączy się  
    case connected = 2       // Połączone
    case disconnecting = 3   // Rozłącza się
}

extension CBPeripheralState {
    var description: String {
        switch self {
        case .disconnected: return "Disconnected"
        case .connecting: return "Connecting"
        case .connected: return "Connected"
        case .disconnecting: return "Disconnecting"
        @unknown default: return "Unknown"
        }
    }
}
