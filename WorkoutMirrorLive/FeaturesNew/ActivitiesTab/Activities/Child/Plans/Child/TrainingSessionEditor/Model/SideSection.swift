//
//  SideSection.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 28/11/2026.
//

import SharedModels

/// Ready-to-render state of the warm-up or cool-down card, built by the editor's State.
struct SideSection: Equatable {

    /// Whether the section is switched on.
    let isOn: Bool

    /// Planned length in minutes.
    let minutes: Int

    /// Written notes (mobility, stretching…).
    let notes: String

    /// The activation or finisher block, if any.
    let block: WorkoutSessionNew?

    /// Whether the block or the notes come first.
    let order: SideBlockOrder

    /// Drag identity of this section's block.
    let blockPart: SidePart

    /// Drag identity of this section's notes.
    let notesPart: SidePart

    /// Part currently lifted by a drag, if any.
    let liftedPart: SidePart?

    /// Part highlighted as the drop target, if any.
    let dropTarget: SidePart?

    /// True while the AI writes the notes — a progress row replaces the field.
    let isGenerating: Bool

    /// What the notes header offers for AI-written notes.
    let generation: SideNotesGeneration
}
