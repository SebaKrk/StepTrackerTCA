//
//  View+ProLocked.swift
//  MyFitnessJournal
//
//  Created by Sebastian Ściuba on 19/11/2026.
//

import SwiftUI

extension View {

    /// Blurs the view under a lock while it needs Pro; a tap on the lock calls `onUnlock`.
    func proLocked(
        _ isLocked: Bool,
        style: ProLockStyle = .badge,
        onUnlock: @escaping () -> Void
    ) -> some View {
        modifier(ProLockedModifier(isLocked: isLocked, style: style, onUnlock: onUnlock))
    }
}
