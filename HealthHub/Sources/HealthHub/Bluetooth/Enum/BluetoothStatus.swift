//
//  BluetoothStatus.swift
//  HealthHub
//
//  Created by Sebastian Sciuba on 05/09/2025.
//

import Foundation

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
        case .ready: return "Gotowy"
        case .disconnected: return "Niepołączony"
        case .unauthorized: return "Brak zgody"
        case .disabled: return "Bluetooth wyłączony"
        case .unsupported: return "Nieobsługiwany"
        case .unknown: return "Sprawdzanie..."
        }
    }
    
    public var buttonText: String {
        switch self {
        case .ready: return "Rozpocznij skanowanie"
        case .disconnected: return "Połącz ponownie"
        case .unauthorized: return "Otwórz ustawienia"
        case .disabled: return "Włącz Bluetooth"
        case .unsupported: return "Nieaktywne"
        case .unknown: return "Czekaj..."
        }
    }
}
