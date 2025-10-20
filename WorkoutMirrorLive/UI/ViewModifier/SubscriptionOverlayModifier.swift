//
//  SubscriptionOverlayModifier.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 18/10/2025.
//

import SwiftUI
import SharedModels

/// A view modifier that manages subscription-based content access with visual overlays.
///
/// This modifier handles the display logic for premium features, showing appropriate
/// overlays based on the user's subscription tier and the required tier for the content.
/// It also manages states like loading, unauthorized access, and missing data.
///
/// ## Usage Example:
/// ```swift
/// ContentView()
///     .subscriptionOverlay(
///         contentState: .ready,
///         subscriptionTier: .basic,
///         requiredTier: .pro,
///         onUnlockTapped: { /* Handle upgrade */ }
///     )
/// ```
struct SubscriptionOverlayModifier: ViewModifier {
    
    // MARK: - Properties
    
    /// The current state of the content (loading, ready, unauthorized, etc.)
    let contentState: ContentState
    
    /// The user's current subscription tier
    let subscriptionTier: SubscriptionTier
    
    /// The minimum subscription tier required to access this content
    let requiredTier: SubscriptionTier
    
    /// Closure called when the user taps the unlock/upgrade button
    let onUnlockTapped: (() -> Void)?
    
    /// Closure called when the user needs to grant health data access
    let onHealthAccessTapped: (() -> Void)?
    
    /// Closure called when the user wants to retry loading data
    let onRetryTapped: (() -> Void)?
    
    // MARK: - Computed Properties
    
    /// Determines if the user has access to the content based on their subscription tier
    ///
    /// Access is granted when:
    /// - Content is ready AND
    /// - User's tier is equal to or higher than the required tier
    private var hasAccess: Bool {
        guard case .ready = contentState else {
            return false
        }
        
        switch (subscriptionTier, requiredTier) {
        case (.basic, .pro), (.basic, .elite):
            return false
        case (.pro, .elite):
            return false
        default:
            return true
        }
    }
    
    /// Determines whether the content should be blurred
    ///
    /// Content is blurred when:
    /// - User lacks access (subscription tier too low)
    /// - Health data authorization is missing
    /// - No data is available
    private var shouldBlur: Bool {
        switch contentState {
        case .ready:
            return !hasAccess
        case .unauthorized, .noData:
            return true
        case .loading:
            return false
        }
    }
    
    // MARK: - ViewModifier Implementation
    
    func body(content: Content) -> some View {
        content
            .blur(radius: shouldBlur ? 3 : 0)
            //.opacity(shouldBlur ? 0.4 : 1.0)
            .overlay { overlayContent }
    }
    
    // MARK: - Private Views
    
    /// Creates the appropriate overlay based on the current state and subscription status
    ///
    /// Displays:
    /// - Upgrade prompts for insufficient subscription tiers
    /// - Health access requests for unauthorized states
    /// - Retry options for missing data
    @ViewBuilder
    private var overlayContent: some View {
        switch contentState {
        case .ready:
            if !hasAccess {
                switch subscriptionTier {
                case .basic:
                    /// Basic users see "Unlock Pro" prompt
                    OverlayView.lockedBasic {
                        onUnlockTapped?()
                    }
                case .pro:
                    /// Pro users see "Go Elite" prompt only if Elite is required
                    if requiredTier == .elite {
                        OverlayView.lockedPro {
                            onUnlockTapped?()
                        }
                    }
                case .elite:
                    /// Elite users have access to everything
                    EmptyView()
                }
            }
            
        case .unauthorized:
            /// Show health access request overlay
            OverlayView.unauthorized {
                onHealthAccessTapped?()
            }
        case .noData:
            /// Show no data overlay with retry option
            OverlayView.noData {
                onRetryTapped?()
            }
        default:
            EmptyView()
        }
    }
}


