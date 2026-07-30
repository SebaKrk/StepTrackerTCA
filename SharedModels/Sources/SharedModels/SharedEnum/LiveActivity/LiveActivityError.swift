//
//  LiveActivityError.swift
//  SharedModels
//
//  Created by Sebastian Sciuba on 23/01/2026.
//

import Foundation

/// Errors that can occur during Live Activity operations.
public enum LiveActivityError: Error, LocalizedError {
    
    /// The specified Live Activity could not be found.
    /// This usually happens if the activity ID is invalid or the activity has already ended.
    case activityNotFound
    
    /// Failed to update the Live Activity content.
    /// This can happen if the payload size exceeds the limit or the system rejects the update.
    case updateFailed
    
    /// Failed to stop the Live Activity.
    /// This might occur if the activity is already in a terminal state.
    case stopFailed
    
    /// An unknown error occurred.
    case unknown
    
    public var errorDescription: String? {
        switch self {
        case .activityNotFound:
            return "The requested Live Activity was not found."
        case .updateFailed:
            return "Failed to update the Live Activity."
        case .stopFailed:
            return "Failed to stop the Live Activity."
        case .unknown:
            return "An unknown error occurred with the Live Activity."
        }
    }
}
