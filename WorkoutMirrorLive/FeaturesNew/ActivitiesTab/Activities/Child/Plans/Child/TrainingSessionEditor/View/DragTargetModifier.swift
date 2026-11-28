//
//  DragTargetModifier.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 28/11/2026.
//

import SwiftUI

/// Makes a warm-up or cool-down part a drop target: dims it while lifted,
/// tints it while a partner hovers, and hands dropped payloads back to the caller.
struct DragTargetModifier: ViewModifier {

    // MARK: - Properties

    /// Whether this part is the one being dragged — shown as a dimmed placeholder.
    let isLifted: Bool

    /// Whether a valid partner is hovering over this part.
    let isTargeted: Bool

    /// Tint of the hover highlight.
    let accent: Color

    /// Reports the drag entering (`true`) or leaving (`false`) this part.
    let onTargeted: (Bool) -> Void

    /// Handles the dropped payloads; returns whether the drop was accepted.
    let onDrop: ([Data]) -> Bool

    // MARK: - Body

    func body(content: Content) -> some View {
        content
            .opacity(isLifted ? liftedOpacity : 1)
            .animation(.easeInOut(duration: 0.2), value: isLifted)
            .background(highlight)
            .dropDestination(for: Data.self) { items, _ in
                onDrop(items)
            } isTargeted: { onTargeted($0) }
    }

    // MARK: - Implementation

    /// Tinted, slightly raised backdrop while a partner hovers over this part.
    private var highlight: some View {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(accent.opacity(isTargeted ? 0.18 : 0))
            .scaleEffect(isTargeted ? 1.02 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isTargeted)
    }

    /// Placeholder opacity of the lifted part.
    private var liftedOpacity: Double { 0.35 }
}
