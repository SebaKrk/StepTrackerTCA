//
//  LiveActivityType.swift
//  SharedModels
//
//  Created by Sebastian Sciuba on 17/01/2026.
//

import Foundation

/// Typ Live Activity obsługiwany przez aplikację
public enum LiveActivityType: String, Codable, Hashable, Sendable {
    case workout  // Trening z HR/Energy
}
