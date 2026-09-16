//
//  BluetoothStatus.swift
//  HealthHub
//
//  Created by Sebastian Sciuba on 05/09/2025.
//

import Foundation
import SwiftUI

public enum BluetoothStatus: Sendable, Equatable {
    
    case ready           // .poweredOn
    case disconnected    // gdy urządzenie się rozłączy
    case unauthorized    // .unauthorized
    case disabled        // .poweredOff
    case unsupported     // .unsupported
    case unknown         // .unknown, .resetting
    
    public var emoji: String {
        switch self {
        case .ready: return "🟢"
        case .disconnected: return "🟡"
        case .unauthorized: return "🔴"
        case .disabled: return "⚪️"
        case .unsupported: return "⚫️"
        case .unknown: return "🔵"
        }
    }
    
    public var labelText: String {
        switch self {
        case .ready: return String(localized: "Active")
        case .disconnected: return String(localized: "Disconnected")
        case .unauthorized: return String(localized: "No permission")
        case .disabled: return String(localized: "Off")
        case .unsupported: return String(localized: "Unsupported")
        case .unknown: return String(localized: "Checking...")
        }
    }
    

    // MARK: - Nowe właściwości dla ContentUnavailableView
    
    /// Tytuł wyświetlany w ContentUnavailableView
    public var title: String {
        switch self {
        case .ready:
            return String(localized: "Bluetooth ready")
        case .disconnected:
            return String(localized: "Connection lost")
        case .unauthorized:
            return String(localized: "Permission required")
        case .disabled:
            return String(localized: "Bluetooth off")
        case .unsupported:
            return String(localized: "Bluetooth unsupported")
        case .unknown:
            return String(localized: "Checking Bluetooth...")
        }
    }
    
    /// Ikona systemowa dla ContentUnavailableView
    public var image: String {
        switch self {
        case .ready:
            return "bluetooth"
        case .disconnected:
            return "bluetooth"
        case .unauthorized:
            return "bluetooth"
        case .disabled:
            return "bluetooth"
        case .unsupported:
            return "bluetooth"
        case .unknown:
            return "bluetooth"
        }
    }
    
    /// Szczegółowy opis dla ContentUnavailableView
    public var description: String {
        switch self {
        case .ready:
            return String(localized: "You can now start scanning for Bluetooth devices")
        case .disconnected:
            return String(localized: "Your Bluetooth device has been disconnected")
        case .unauthorized:
            return String(localized: "Allow Bluetooth access in Settings to connect to a heart rate monitor")
        case .disabled:
            return String(localized: "Turn on Bluetooth to connect to a heart rate monitor and other devices")
        case .unsupported:
            return String(localized: "This device doesn't support Bluetooth Low Energy required by heart rate monitors")
        case .unknown:
            return String(localized: "Please wait while we initialize the Bluetooth connection")
        }
    }
    
    /// Tekst przycisku dla ContentUnavailableView
    public var buttonTitle: String? {
        switch self {
        case .ready:
            return String(localized: "start scanning")
        case .disconnected:
            return String(localized: "try again")
        case .unauthorized:
            return String(localized: "open settings")
        case .disabled:
            return String(localized: "open bluetooth settings")
        case .unsupported:
            return nil
        case .unknown:
            return String(localized: "retry")
        }
    }

}
