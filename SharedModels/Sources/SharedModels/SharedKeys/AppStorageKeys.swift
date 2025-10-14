//
//  AppStorageKeys.swift
//  SharedModels
//
//  Created by Sebastian Sciuba on 14/10/2025.
//

import Foundation

/// Centralized storage keys for AppStorage and UserDefaults.
///
/// This enum provides type-safe string keys for persistent storage,
/// eliminating hardcoded strings and reducing typos across the codebase.
///
/// ## Usage
/// ```swift
/// // In SharedKeys.swift
/// static var subscriptionTier: Self {
///     appStorage(AppStorageKeys.subscriptionTier).default(.basic)
/// }
/// ```
public enum AppStorageKeys {
    
    // MARK: - User Preferences
    
    /// Storage key for user's subscription tier (basic, premium, pro)
    public static let subscriptionTier = "userSubscriptionTier"
    
}
