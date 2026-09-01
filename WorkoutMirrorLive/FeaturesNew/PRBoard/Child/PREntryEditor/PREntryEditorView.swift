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
        }
    }

    // MARK: - Structure

    private var content: some View {
        Form {
            resultSection
            detailsSection
            equipmentSection
            noteSection
        }
        .scrollDismissesKeyboard(.interactively)
        .dismissesKeyboardOnBackgroundTap()
    }

    private var resultSection: some View {
        Section(String(localized: "Result")) {
            weightRow
            dateRow
            if store.movement.supportsRxScaled {
                rxScaledRow
            }
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
        HStack {
            Text(String(localized: "Weight"))
            Spacer()
            TextField("0", text: $store.weightText)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 90)
            Text("kg")
                .foregroundStyle(.secondary)
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
            ForEach(PRContext.allCases, id: \.self) { context in
                Text(context.displayName).tag(context)
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

    private var noteRow: some View {
        TextField(String(localized: "Optional note"), text: $store.note, axis: .vertical)
            .lineLimit(2...)
    }

    private var rpeValues: [Double] {
        stride(from: 6.0, through: 10.0, by: 0.5).map { $0 }
    }

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
