//
//  ContentOverlay.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 18/10/2025.
//

import SwiftUI
import SharedModels

extension View {
    /// Adds an overlay depending on the `ContentState` and user access level.
    ///
    /// - Parameters:
    ///   - contentState: Current content state (.loading, .unauthorized, .noData, .ready).
    ///   - hasAccess: Indicates whether the user has access to the feature.
    ///   - onUnlock: Called when user taps “Unlock Premium”.
    ///   - onRequestAccess: Called when user taps “Grant Access”.
    ///   - onRetry: Called when user taps “Try Again” or “Refresh”.
    ///
    /// - Returns: A view with an appropriate overlay applied.
    func contentOverlay(
        contentState: ContentState,
        hasAccess: Bool = true,
        onUnlock: (() -> Void)? = nil,
        onRequestAccess: (() -> Void)? = nil,
        onRetry: (() -> Void)? = nil
    ) -> some View {
        overlay {
            overlayContent(
                for: contentState,
                hasAccess: hasAccess,
                onUnlock: onUnlock,
                onRequestAccess: onRequestAccess,
                onRetry: onRetry
            )
        }
    }

    // MARK: - Private Overlay Builder

    @ViewBuilder
    private func overlayContent(
        for state: ContentState,
        hasAccess: Bool,
        onUnlock: (() -> Void)?,
        onRequestAccess: (() -> Void)?,
        onRetry: (() -> Void)?
    ) -> some View {
        switch state {
        case .loading:
         EmptyView()

        case .unauthorized:
            ChartOverlayView.unauthorized {
                onRequestAccess?()
            }

        case .noData:
            ChartOverlayView.noData {
                onRetry?()
            }

        case .ready(let tier):
            if !hasAccess {
                overlayForTier(tier, onUnlock: onUnlock)
            } else {
                EmptyView()
            }
        }
    }

    // MARK: - Subscription Overlay Logic

    @ViewBuilder
    private func overlayForTier(
        _ tier: SubscriptionTier,
        onUnlock: (() -> Void)?
    ) -> some View {
        switch tier {
        case .basic:
            ChartOverlayView(
                icon: "lock.fill",
                iconColor: .yellow,
                title: "Upgrade to Pro to Unlock",
                buttonIcon: "crown.fill",
                buttonText: "Go Pro",
                buttonColor: .yellow,
                action: { onUnlock?() }
            )

        case .pro:
            ChartOverlayView(
                icon: "lock.fill",
                iconColor: .orange,
                title: "Upgrade to Elite for More Insights",
                buttonIcon: "flame.fill",
                buttonText: "Go Elite",
                buttonColor: .orange,
                action: { onUnlock?() }
            )

        case .elite:
            EmptyView() // Full access
        }
    }
}
