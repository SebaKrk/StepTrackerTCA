//
//  BluetoothError.swift
//  HealthHub
//
//  Created by Sebastian Sciuba on 03/09/2025.
//

import Foundation

/// Błędy które może rzucić Bluetooth Manager
public enum BluetoothError: Error, Sendable {
    case notPoweredOn
    case scanningFailed
}
