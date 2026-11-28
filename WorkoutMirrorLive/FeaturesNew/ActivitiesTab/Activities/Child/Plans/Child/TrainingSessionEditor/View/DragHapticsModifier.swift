//
//  DragHapticsModifier.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 28/11/2026.
//

import SharedModels
import SwiftUI

/// Haptics of the warm-up / cool-down reorder: lift, hovering a valid partner, and the swap itself.
struct DragHapticsModifier: ViewModifier {

    // MARK: - Properties

    /// Lifted part (iOS 27 only; `nil` on iOS 26, which plays the lift haptic imperatively).
    let liftedPart: SidePart?

    /// Partner part a dragged grip is hovering over.
    let dropTarget: SidePart?

    /// Warm-up order — a change means the parts just swapped.
    let warmUpOrder: SideBlockOrder?

    /// Cool-down order — a change means the parts just swapped.
    let coolDownOrder: SideBlockOrder?

    // MARK: - Body

    func body(content: Content) -> some View {
        content
            .sensoryFeedback(.impact(weight: .medium), trigger: liftedPart) { _, part in part != nil }
            .sensoryFeedback(.selection, trigger: dropTarget) { _, target in target != nil }
            .sensoryFeedback(.impact(flexibility: .rigid), trigger: warmUpOrder) { _, order in order != nil }
            .sensoryFeedback(.impact(flexibility: .rigid), trigger: coolDownOrder) { _, order in order != nil }
    }
}
