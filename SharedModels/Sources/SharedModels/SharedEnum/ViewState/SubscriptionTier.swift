//
//  SubscriptionTier.swift
//  SharedModels
//
//  Created by Sebastian Sciuba on 01/10/2025.
//

import Foundation

public enum SubscriptionTier: String, Equatable {
    
    case basic = "Basic"
    
    case pro = "Pro"
    
    case elite = "Elite"
    
    var name: String { rawValue }
}
