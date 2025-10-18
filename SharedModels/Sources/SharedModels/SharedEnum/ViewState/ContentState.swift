//
//  ContentState.swift
//  SharedModels
//
//  Created by Sebastian Sciuba on 01/10/2025.
//

import Foundation

public enum ContentState: Equatable {
    
    case loading
    
    case unauthorized
    
    case noData
    
    case ready(SubscriptionTier)
    
}
