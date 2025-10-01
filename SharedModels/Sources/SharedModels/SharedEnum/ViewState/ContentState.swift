//
//  ContentState.swift
//  SharedModels
//
//  Created by Sebastian Sciuba on 01/10/2025.
//

import Foundation

public enum ContentState: Equatable {
    
    /// Content is being loaded
    case loading
    
    /// Content is ready to display
    case success
    
    /// Content failed to load
    case error(String? = nil)
    
    /// Content is locked behind paywall
    case locked(LockedReason)
    
    /// Missing required permissions
    case unauthorized
    
}

