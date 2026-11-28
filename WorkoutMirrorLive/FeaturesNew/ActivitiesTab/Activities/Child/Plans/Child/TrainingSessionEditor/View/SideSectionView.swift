//
//  SideSectionView.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 28/11/2026.
//

import SharedModels
import SwiftUI
import UniformTypeIdentifiers

/// Body of the warm-up or cool-down card: duration, notes and the activation/finisher block,
/// with the block and notes swappable by dragging either grip onto the other.
struct SideSectionView: View {

    // MARK: - Properties

    /// Ready-to-render section state from the editor's Feature.
    let section: SideSection

    /// Title of the row that adds the block ("Add activation" / "Add finisher").
    let addBlockTitle: LocalizedStringKey

    /// Placeholder of the notes field.
    let notesPlaceholder: LocalizedStringKey

    /// Accent used for the drop highlight.
    let accent: Color

    /// Called with the new duration in minutes.
    let onMinutesChange: (Int) -> Void

    /// Called with the edited notes.
    let onNotesChange: (String) -> Void

    /// Opens the block editor (add or edit).
    let onEditBlock: () -> Void

    /// Asks to remove the block.
    let onRemoveBlock: () -> Void

    /// Swaps block and notes without dragging (VoiceOver).
    let onSwap: () -> Void

    /// A grip was lifted.
    let onLift: (SidePart) -> Void

    /// The drag ended, dropped or cancelled (iOS 27+).
    let onDragEnd: () -> Void

    /// A dragged grip entered or left a part.
    let onTargeted: (SidePart, Bool) -> Void

    /// A dragged part landed on a part; returns whether the drop was accepted.
    let onDrop: (SidePart, SidePart) -> Bool

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            durationRow
            Divider().padding(.leading)
            if section.order == .blockFirst {
                blockSlot
                Divider().padding(.leading)
                notesSection
                    .transition(.opacity)
            } else {
                notesSection
                    .transition(.opacity)
                Divider().padding(.leading)
                blockSlot
            }
        }
        .animation(.default, value: section.block)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: section.order)
    }

    // MARK: - Structure

    private var durationRow: some View {
        row {
            durationLabel
            Spacer()
            durationStepper
        }
    }

    @ViewBuilder
    private var blockSlot: some View {
        if let block = section.block {
            blockRow(block)
                .modifier(dragTarget(section.blockPart))
                .transition(.opacity)
        } else {
            addBlockRow
                .transition(.opacity)
        }
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            row {
                notesLabel
                Spacer()
                if section.block != nil {
                    grip(section.notesPart)
                }
            }
            Divider().padding(.leading)
            notesField
        }
        .modifier(dragTarget(section.notesPart))
    }

    private func blockRow(_ block: WorkoutSessionNew) -> some View {
        row {
            Button {
                onEditBlock()
            } label: {
                HStack {
                    blockSummary(block)
                    Spacer()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            removeBlockButton
            grip(section.blockPart)
        }
    }

    private var addBlockRow: some View {
        Button {
            onEditBlock()
        } label: {
            row {
                Label(addBlockTitle, systemImage: "plus.circle")
                    .foregroundStyle(.tint)
                Spacer()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    /// Grip that lifts the whole block or notes card; dropping it on the other part swaps them.
    private func grip(_ part: SidePart) -> some View {
        Group {
            if #available(iOS 27, *) {
                gripIcon
                    .draggable(part.dragPayload) { dragPreview(part) }
                    .onDragSessionUpdated { session in dragSessionChanged(part, phase: session.phase) }
            } else {
                gripIcon
                    .onDrag { lifted(part) } preview: { dragPreview(part) }
            }
        }
        .accessibilityLabel(Text("Reorder"))
        .accessibilityAction { onSwap() }
    }

    /// The whole card under the finger — the grip alone is too small to show what is being moved.
    @ViewBuilder
    private func dragPreview(_ part: SidePart) -> some View {
        Group {
            if part == section.blockPart, let block = section.block {
                blockSummary(block)
            } else {
                notesPreview
            }
        }
        .padding(12)
        .frame(width: 280, alignment: .leading)
        .background(previewBackground, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    // MARK: - Drag

    /// Lift state, drop target highlight and drop handling for one part.
    private func dragTarget(_ part: SidePart) -> DragTargetModifier {
        DragTargetModifier(
            isLifted: isLifted(part),
            isTargeted: section.dropTarget == part,
            accent: accent,
            onTargeted: { onTargeted(part, $0) },
            onDrop: { items in
                guard let data = items.first, let dropped = SidePart(dragPayload: data) else { return false }
                return onDrop(dropped, part)
            }
        )
    }

    /// iOS 27 reports the drag's end, so the source can dim while lifted and the lift state never goes stale.
    @available(iOS 27, *)
    private func dragSessionChanged(_ part: SidePart, phase: DragSession.Phase) {
        switch phase {
        case .active:
            // `.initial` isn't guaranteed; `.active` repeats, so the Feature dedupes and the parent plays the haptic from state.
            onLift(part)
        case .ended, .dataTransferCompleted:
            onDragEnd()
        default:
            break
        }
    }

    /// iOS 26 lift: imperative haptic (a repeat lift leaves state unchanged), Feature notified, in-app-only payload.
    private func lifted(_ part: SidePart) -> NSItemProvider {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        onLift(part)
        let payload = part.dragPayload
        let provider = NSItemProvider()
        provider.registerDataRepresentation(forTypeIdentifier: UTType.data.identifier, visibility: .ownProcess) { completion in
            completion(payload, nil)
            return nil
        }
        return provider
    }

    /// Dims only on iOS 27, where the drag's end is known and the dim can't stick.
    private func isLifted(_ part: SidePart) -> Bool {
        guard #available(iOS 27, *) else { return false }
        return section.liftedPart == part
    }

    // MARK: - Implementation

    private var durationLabel: some View {
        Text("Duration").foregroundStyle(.secondary)
    }

    private var durationStepper: some View {
        Stepper(
            "\(section.minutes) min",
            value: Binding(get: { section.minutes }, set: { onMinutesChange($0) }),
            in: 1...120,
            step: 1
        )
        .fixedSize()
    }

    private var notesLabel: some View {
        Text("Description").foregroundStyle(.secondary)
    }

    private var notesField: some View {
        TextField(
            notesPlaceholder,
            text: Binding(get: { section.notes }, set: { onNotesChange($0) }),
            axis: .vertical
        )
        .padding(.horizontal, 4)
        .padding(.vertical, 10)
    }

    private var removeBlockButton: some View {
        Button(role: .destructive) {
            onRemoveBlock()
        } label: {
            Image(systemName: "trash")
                .foregroundStyle(.red.opacity(0.7))
        }
        .buttonStyle(.plain)
    }

    /// Three-line grip icon with a finger-sized hit area.
    private var gripIcon: some View {
        Image(systemName: "line.3.horizontal")
            .font(.body)
            .foregroundStyle(.tertiary)
            .frame(width: 32, height: 36)
            .contentShape(Rectangle())
    }

    private func blockSummary(_ block: WorkoutSessionNew) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(block.name)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.primary)
            HStack(spacing: 6) {
                blockTypeBadge(block.type)
                Text("\(block.exercises.count) exercises")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func blockTypeBadge(_ type: ExerciseWorkoutType) -> some View {
        Text(type.displayName.uppercased())
            .font(.caption2)
            .fontWeight(.semibold)
            .foregroundStyle(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(type.color.opacity(0.8))
            .cornerRadius(4)
    }

    private var notesPreview: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Description")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.primary)
            if !section.notes.isEmpty {
                Text(section.notes)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
    }

    private var previewBackground: Color {
        Color(uiColor: .secondarySystemBackground)
    }

    private func row<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        HStack { content() }
            .padding(.vertical, 10)
            .padding(.horizontal, 4)
    }
}
