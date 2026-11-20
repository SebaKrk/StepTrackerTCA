//
//  ProLockedModifier.swift
//  MyFitnessJournal
//
//  Created by Sebastian Ściuba on 19/11/2026.
//

import SwiftUI

/// Blurs content that needs Pro, takes its touches away and puts a lock over it.
struct ProLockedModifier: ViewModifier {

    // MARK: - Properties

    /// Whether the content needs Pro.
    let isLocked: Bool

    /// How the lock presents itself.
    let style: ProLockStyle

    /// Called when the locked content is tapped.
    let onUnlock: () -> Void

    // MARK: - Body (structure)

    func body(content: Content) -> some View {
        content
            .blur(radius: isLocked ? 3 : 0)
            .allowsHitTesting(!isLocked)
            .overlay {
                if isLocked {
                    lockOverlay
                        .transition(.opacity)
                }
            }
            .animation(.default, value: isLocked)
    }

    @ViewBuilder
    private var lockOverlay: some View {
        switch style {
        case .badge:
            lockBadgeButton
        case .prompt:
            unlockPrompt
        }
    }

    // MARK: - Implementation

    private var lockBadgeButton: some View {
        Button {
            onUnlock()
        } label: {
            lockBadge
        }
        .buttonStyle(.plain)
    }

    private var lockBadge: some View {
        Image(systemName: "lock.fill")
            .font(.title2)
            .foregroundStyle(ProGold.lock)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
    }

    private var unlockPrompt: some View {
        OverlayView.lockedBasic {
            onUnlock()
        }
    }
}
