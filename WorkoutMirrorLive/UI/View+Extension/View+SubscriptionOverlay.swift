//
//  View+SubscriptionOverlay.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 18/10/2025.
//

import SharedModels
import SwiftUI

extension View {
    /// Applies subscription-based content access overlay to the view
    ///
    /// This modifier manages the visual presentation of premium content,
    /// showing appropriate overlays and blur effects based on the user's
    /// subscription status and content state.
    ///
    /// - Parameters:
    ///   - contentState: The current state of the content
    ///   - subscriptionTier: The user's current subscription level
    ///   - requiredTier: The minimum subscription level required for this content
    ///   - onUnlockTapped: Optional closure called when upgrade button is tapped
    ///   - onHealthAccessTapped: Optional closure called when health access is needed
    ///   - onRetryTapped: Optional closure called when retry button is tapped
    ///
    /// - Returns: A view with subscription overlay applied
    ///
    /// ## Example:
    /// ```swift
    /// ChartView()
    ///     .subscriptionOverlay(
    ///         contentState: store.contentState,
    ///         subscriptionTier: store.subscriptionTier,
    ///         requiredTier: .pro,
    ///         onUnlockTapped: {
    ///             store.send(.unlockButtonTapped)
    ///         }
    ///     )
    /// ```
    func subscriptionOverlay(
        contentState: ContentState,
        subscriptionTier: SubscriptionTier,
        requiredTier: SubscriptionTier,
        onUnlockTapped: (() -> Void)? = nil,
        onHealthAccessTapped: (() -> Void)? = nil,
        onRetryTapped: (() -> Void)? = nil
    ) -> some View {
        self.modifier(
            SubscriptionOverlayModifier(
                contentState: contentState,
                subscriptionTier: subscriptionTier,
                requiredTier: requiredTier,
                onUnlockTapped: onUnlockTapped,
                onHealthAccessTapped: onHealthAccessTapped,
                onRetryTapped: onRetryTapped
            )
        )
    }
    
}
