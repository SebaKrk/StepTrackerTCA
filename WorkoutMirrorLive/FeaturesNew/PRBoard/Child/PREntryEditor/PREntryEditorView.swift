//
//  PREntryEditorView.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 01/09/2026.
//

import ComposableArchitecture
import SharedModels
import SwiftUI

@ViewAction(for: PREntryEditorFeature.self)
struct PREntryEditorView: View {
    @Bindable var store: StoreOf<PREntryEditorFeature>

    var body: some View {
        NavigationStack {
            content
                .navigationTitle(store.movement.name)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    cancelToolbarItem
                    saveToolbarItem
                }
                .alert($store.scope(state: \.alert, action: \.alert))
        }
    }

    // MARK: - Structure

    private var content: some View {
        Form {
            resultSections
            detailsSection
            equipmentSection
            noteSection
        }
        .scrollDismissesKeyboard(.interactively)
        .dismissesKeyboardOnBackgroundTap()
    }

    /// Time gets a section of its own — the wheel card and the plain metadata
    /// rows don't share a surface well; the other score types stay inline.
    @ViewBuilder
    private var resultSections: some View {
        switch store.movement.scoreType {
        case .time:
            Section(String(localized: "Result")) {
                timeRow
            }
            Section {
                resultMetadataRows
            }
        case .weight, .reps, .amrap:
            Section(String(localized: "Result")) {
                scoreRow
                resultMetadataRows
            }
        }
    }

    /// Rows shared by every score type: date, Rx/Scaled, scaling note.
    @ViewBuilder
    private var resultMetadataRows: some View {
        dateRow
        if store.movement.supportsRxScaled {
            rxScaledRow
        }
        if store.movement.supportsRxScaled && !store.isRx {
            scalingNoteRow
        }
    }

    /// Inline input of the non-time score types (time renders its own section).
    @ViewBuilder
    private var scoreRow: some View {
        switch store.movement.scoreType {
        case .weight:
            weightRow
        case .reps:
            repsRow
        case .amrap:
            amrapRow
        case .time:
            EmptyView()
        }
    }

    private var detailsSection: some View {
        Section(String(localized: "Details")) {
            contextRow
            rpeRow
        }
    }

    private var equipmentSection: some View {
        Section(String(localized: "Equipment")) {
            ForEach(PREquipment.allCases, id: \.self) { item in
                equipmentRow(item)
            }
        }
    }

    private var noteSection: some View {
        Section(String(localized: "Note")) {
            noteRow
        }
    }

    // MARK: - Implementation

    private var weightRow: some View {
        numericRow(
            String(localized: "Weight"),
            text: $store.weightText,
            suffix: "kg",
            keyboard: .decimalPad
        )
    }

    private var repsRow: some View {
        numericRow(
            String(localized: "Reps"),
            text: $store.repsText,
            keyboard: .numberPad
        )
    }

    private var amrapRow: some View {
        DNFFields(
            title: String(localized: "Score"),
            rounds: store.amrapRounds,
            extraReps: store.amrapExtraReps,
            onRounds: { $store.amrapRounds.wrappedValue = $0 },
            onExtraReps: { $store.amrapExtraReps.wrappedValue = $0 }
        )
        // Stepper tiles need contrast against the section cell — the lighter
        // .native inner surface is the point here, unlike the full-bleed time card.
        .environment(\.summaryPalette, .native)
    }

    private var timeRow: some View {
        TimePickerField(
            minutes: store.timeMinutes,
            seconds: store.timeSeconds,
            maxMinutes: 99,
            onMinutes: { $store.timeMinutes.wrappedValue = $0 },
            onSeconds: { $store.timeSeconds.wrappedValue = $0 }
        )
        // The field carries its own Summary-style card — drop the Form row
        // chrome and paint the card with the section surface itself, so the
        // field blends into the grouped cell instead of sitting on it.
        .environment(\.summaryPalette, Self.formBlendedPalette)
        .listRowInsets(EdgeInsets())
        .listRowBackground(Color.clear)
    }

    private func numericRow(
        _ label: String,
        text: Binding<String>,
        suffix: String? = nil,
        keyboard: UIKeyboardType
    ) -> some View {
        HStack {
            Text(label)
            Spacer()
            TextField("0", text: text)
                .keyboardType(keyboard)
                .multilineTextAlignment(.trailing)
                .frame(width: 90)
            if let suffix {
                Text(suffix)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var dateRow: some View {
        DatePicker(
            String(localized: "Date"),
            selection: $store.date,
            in: ...store.maxDate,
            displayedComponents: .date
        )
    }

    private var rxScaledRow: some View {
        Picker(String(localized: "Standard"), selection: $store.isRx) {
            Text("Rx").tag(true)
            Text(String(localized: "Scaled")).tag(false)
        }
        .pickerStyle(.segmented)
    }

    private var contextRow: some View {
        Picker(String(localized: "Context"), selection: $store.context) {
            Text("—").tag(PRContext?.none)
            ForEach(PRContext.allCases, id: \.self) { context in
                Text(context.displayName).tag(PRContext?.some(context))
            }
        }
        .pickerStyle(.segmented)
    }

    private var rpeRow: some View {
        Picker(String(localized: "RPE"), selection: $store.rpe) {
            Text("—").tag(Double?.none)
            ForEach(rpeValues, id: \.self) { value in
                Text(value.formatted(.number.precision(.fractionLength(0...1))))
                    .tag(Double?.some(value))
            }
        }
        .pickerStyle(.menu)
    }

    private func equipmentRow(_ item: PREquipment) -> some View {
        Button {
            send(.equipmentToggled(item))
        } label: {
            HStack {
                Image(systemName: item.sfSymbolName)
                    .frame(width: 24)
                    .foregroundStyle(.secondary)
                Text(item.displayName)
                    .foregroundStyle(.primary)
                Spacer()
                if store.equipment.contains(item) {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.tint)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var scalingNoteRow: some View {
        TextField(String(localized: "What did you scale?"), text: $store.scalingNoteText)
    }

    private var noteRow: some View {
        TextField(String(localized: "Optional note"), text: $store.note, axis: .vertical)
            .lineLimit(2...)
    }

    private var rpeValues: [Double] {
        stride(from: 6.0, through: 10.0, by: 0.5).map { $0 }
    }

    /// TimePickerField skin matching the Form's grouped-cell surface exactly —
    /// same background, no stroke, system ink (the .native skin uses the lighter
    /// tertiary surface and visibly cuts out of the section).
    private static let formBlendedPalette = SummaryPalette(
        background: .clear,
        card: Color(.secondarySystemGroupedBackground),
        cardInner: Color(.secondarySystemGroupedBackground),
        stroke: .clear,
        strokeWidth: 0,
        ink: .primary,
        inkSecondary: .secondary,
        inkTertiary: Color(.tertiaryLabel),
        mint: SummaryTheme.mint,
        strengthChip: SummaryTheme.strengthChip,
        wodChip: SummaryTheme.wodChip,
        onAccent: .white
    )

    @ToolbarContentBuilder
    private var cancelToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            cancelButton
        }
    }

    @ToolbarContentBuilder
    private var saveToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            saveButton
        }
    }

    private var cancelButton: some View {
        Button {
            send(.cancelTapped)
        } label: {
            Text(String(localized: "Cancel"))
        }
    }

    private var saveButton: some View {
        Button {
            send(.saveTapped)
        } label: {
            Text(String(localized: "Save"))
                .fontWeight(.semibold)
        }
        .disabled(store.isSaveDisabled)
    }
}

#Preview {
    PREntryEditorView(
        store: Store(
            initialState: PREntryEditorFeature.State(
                movement: PRCatalog.movement(id: "back-squat") ?? PRCatalog.movements[0],
                now: Date(timeIntervalSince1970: 1_700_000_000)
            )
        ) {
            PREntryEditorFeature()
        }
    )
}
