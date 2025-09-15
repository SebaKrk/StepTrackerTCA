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
    
    // MARK: - Nowe właściwości dla ContentUnavailableView
    
    /// Tytuł wyświetlany w ContentUnavailableView
    public var title: String {
        switch self {
        case .ready:
            return "Bluetooth gotowy"
        case .disconnected:
            return "Połączenie przerwane"
        case .unauthorized:
            return "Wymagane uprawnienia"
        case .disabled:
            return "Bluetooth wyłączony"
        case .unsupported:
            return "Bluetooth nieobsługiwany"
        case .unknown:
            return "Sprawdzanie Bluetooth..."
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
            return "Możesz teraz rozpocząć skanowanie urządzeń Bluetooth"
        case .disconnected:
            return "Twoje urządzenie Bluetooth zostało rozłączone"
        case .unauthorized:
            return "Zezwól na dostęp do Bluetooth w Ustawieniach, aby połączyć się z monitorem tętna"
        case .disabled:
            return "Włącz Bluetooth, aby połączyć się z monitorem tętna i innymi urządzeniami"
        case .unsupported:
            return "To urządzenie nie obsługuje Bluetooth Low Energy wymaganego przez monitory tętna"
        case .unknown:
            return "Poczekaj, aż zainicjujemy połączenie Bluetooth"
        }
    }
    
    /// Tekst przycisku dla ContentUnavailableView
    public var buttonTitle: String? {
        switch self {
        case .ready:
            return "rozpocznij skanowanie"
        case .disconnected:
            return "spróbuj ponownie"
        case .unauthorized:
            return "otwórz ustawienia"
        case .disabled:
            return "otwórz ustawienia bluetooth"
        case .unsupported:
            return nil
        case .unknown:
            return "ponów próbę"
        }
    }

}
