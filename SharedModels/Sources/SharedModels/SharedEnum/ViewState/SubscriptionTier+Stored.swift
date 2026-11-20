//
//  SubscriptionTier+Stored.swift
//  SharedModels
//
//  Created by Sebastian Ściuba on 19/11/2026.
//

import Foundation

extension SubscriptionTier {

    /// The tier the app has stored, read once without observing it — for code that runs outside a screen.
    public static var stored: SubscriptionTier {
        UserDefaults.standard
            .string(forKey: AppStorageKeys.subscriptionTier)
            .flatMap(SubscriptionTier.init(rawValue:)) ?? .basic
    }
}
