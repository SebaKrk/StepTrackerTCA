//
//  SubscriptionTier.swift
//  SharedModels
//
//  Created by Sebastian Sciuba on 01/10/2025.
//

import Foundation

public enum SubscriptionTier: String, Equatable, CaseIterable, Identifiable, Sendable {
    
    case basic = "basic"
    
    case pro = "pro"
    
    case elite = "elite"
    
    public var id: Self { self }
    
    public var name: String {
        switch self {
        case .basic:
            return "Basic"
        case .pro:
            return "Pro"
        case .elite:
            return "Elite"
        }
    }
}
