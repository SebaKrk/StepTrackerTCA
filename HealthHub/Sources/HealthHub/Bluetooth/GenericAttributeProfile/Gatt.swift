//
//  Gatt.swift
//  HealthHub
//
//  Created by Sebastian Sciuba on 02/09/2025.
//

@preconcurrency
import CoreBluetooth

/// Generic Attribute Profile
public enum Gatt {
    
    public enum Service: Sendable {
        public static let heartRate = CBUUID(string: "180D")
    }
    
    public enum Characteristic: Sendable {
        public static let heartRateMeasurement = CBUUID(string: "2A37")
    }
}
