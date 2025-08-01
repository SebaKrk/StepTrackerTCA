//
//  SensorStatus.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 01/08/2025.
//

import Foundation

enum SensorStatus {
    
    case authorized
    case disconnected
    case unauthorized
    case disabled
    
    var emoji: String {
        switch self {
        case .authorized: return "🟢"
        case .disconnected: return "🟡"
        case .unauthorized: return "🔴"
        case .disabled: return "⚪️"
        }
    }
    
    var labelText: String {
        switch self {
        case .authorized: return "Ok"
        case .disconnected: return "Niepołączony"
        case .unauthorized: return "Brak zgody"
        case .disabled: return "Wyłączony"
        }
    }
}
