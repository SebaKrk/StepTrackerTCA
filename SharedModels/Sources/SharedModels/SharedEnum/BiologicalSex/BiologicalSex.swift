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
            return "Male"
        case .female:
            return "Female"
        case .notSet:
            return "Not Set"
        case .unknown:
            return "Unknown"
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
