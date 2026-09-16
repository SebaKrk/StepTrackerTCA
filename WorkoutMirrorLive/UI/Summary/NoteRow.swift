//
//  NoteRow.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 27/07/2026.
//

import SwiftUI

/// WOD note: quiet "+ Dodaj notatkę" → single-line field (keyboard Done
/// commits, collapsing never clears the text) → saved row, tappable to re-edit.
/// Available in every card phase; the text lives in `result.note`.
struct NoteRow: View {

    // MARK: - Properties

    let state: WODScoringFeature.NoteRowState
    let text: String
    let onAdd: () -> Void
    let onTextChange: (String) -> Void
    let onCommit: () -> Void
    let onEditSaved: () -> Void
    @Environment(\.summaryPalette) private var theme
    // MARK: - Body

    var body: some View {
        switch state {
        case .empty:
            addNoteButton
        case .editing:
            noteField
        case .saved:
            savedNote
        }
    }

    // MARK: - Implementation

    private var addNoteButton: some View {
        Button {
            onAdd()
        } label: {
            Text(String(localized: "+ Add note"))
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(theme.inkTertiary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }

    private var noteField: some View {
        TextField(
            String(localized: "Note"),
            text: Binding(get: { text }, set: onTextChange)
        )
        .font(.system(size: 13))
        .foregroundStyle(theme.ink)
        .submitLabel(.done)
        .onSubmit { onCommit() }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.04), in: .rect(cornerRadius: SummaryTheme.innerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: SummaryTheme.innerRadius)
                .stroke(theme.stroke, lineWidth: 1)
        )
    }

    private var savedNote: some View {
        Button {
            onEditSaved()
        } label: {
            Text("\(Text(String(localized: "Note:")).fontWeight(.semibold).foregroundColor(theme.ink)) \(text)")
                .font(.system(size: 13))
                .foregroundStyle(theme.inkSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.04), in: .rect(cornerRadius: SummaryTheme.innerRadius))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Previews

#Preview("NoteRow — 3 stany (galeria 10)") {
    VStack(spacing: 16) {
        VStack {
            NoteRow(
                state: .empty,
                text: "",
                onAdd: {},
                onTextChange: { _ in },
                onCommit: {},
                onEditSaved: {}
            )
        }
        .summaryCard()

        VStack {
            NoteRow(
                state: .editing,
                text: "thrustery łamane po 10",
                onAdd: {},
                onTextChange: { _ in },
                onCommit: {},
                onEditSaved: {}
            )
        }
        .summaryCard()

        VStack {
            NoteRow(
                state: .saved,
                text: "thrustery łamane po 10 od trzeciej rundy.",
                onAdd: {},
                onTextChange: { _ in },
                onCommit: {},
                onEditSaved: {}
            )
        }
        .summaryCard()
    }
    .padding(16)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(SummaryTheme.background)
}
