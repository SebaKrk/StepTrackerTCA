//
//  LockedReason.swift
//  SharedModels
//
//  Created by Sebastian Sciuba on 01/10/2025.
//

import Foundation

public enum LockedReason: Equatable {
    
    /// Basic paywall - feature requires premium
    case requiresPremium
    
    /// Trial expired
    case trialExpired
    
    /// Feature requires specific subscription tier
    case requiresTier(SubscriptionTier)
    
    var title: String {
        switch self {
        case .requiresPremium:
            return "Premium Feature"
        case .trialExpired:
            return "Trial Expired"
        case .requiresTier(let tier):
            return "Requires \(tier.name)"
        }
    }
    
    var message: String {
        switch self {
        case .requiresPremium:
            return "Unlock advanced analytics with Premium"
        case .trialExpired:
            return "Your trial has ended. Subscribe to continue"
        case .requiresTier(let tier):
            return "This feature is available in \(tier.name) plan"
        }
    }
}
