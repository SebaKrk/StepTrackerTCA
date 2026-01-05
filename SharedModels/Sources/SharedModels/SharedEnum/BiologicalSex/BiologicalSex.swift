//
//  BiologicalSex.swift
//  SharedModels
//
//  Created by Sebastian Sciuba on 25/09/2025.
//

import Foundation

public enum BiologicalSex: String, CaseIterable, Equatable, Sendable {
    
    case male
    case female
    case notSet
    case unknown

    public var displayName: String {
        switch self {
        case .male:
            return String(localized: "Male", bundle: .module)
        case .female:
            return String(localized: "Female", bundle: .module)
        case .notSet:
            return String(localized: "Not Set", bundle: .module)
        case .unknown:
            return String(localized: "Unknown", bundle: .module)
        }
    }
    
    public var abbreviation: String {
        switch self {
        case .male:
            return "M"
        case .female:
            return "F"
        case .notSet:
            return "-"
        case .unknown:
            return "?"
        }
    }
}
