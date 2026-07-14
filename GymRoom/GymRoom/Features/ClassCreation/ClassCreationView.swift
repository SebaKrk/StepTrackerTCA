//
//  ClassCreationView.swift
//  GymRoom
//
//  Created by Sebastian Ściuba on 13/06/2026.
//

import ComposableArchitecture
import SwiftUI

/// Sheet do tworzenia nowej klasy. 3 pola: name (mandatory), location (mandatory),
/// scheduled date (optional, toggle).
@ViewAction(for: ClassCreationFeature.self)
struct ClassCreationView: View {

    @Bindable var store: StoreOf<ClassCreationFeature>

    /// Focus tracking dla TextField'ów. Tap-outside-form + "Done" button w keyboard
    /// toolbar resetują na `nil` → dismiss klawiatury.
    @FocusState private var focusedField: Field?

    private enum Field: Hashable {
        case name
        case location
    }

    var body: some View {
        NavigationStack {
            Form {
                detailsSection
                scheduleSection
                capacitySection
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                toolbarContent
                keyboardToolbar
            }
            .simultaneousGesture(
                // Tap w obrębie Form'a ale poza TextField'em → dismiss klawiatury.
                // `simultaneousGesture` NIE blokuje innych gesture'ów (Toggle, Stepper,
                // DatePicker dalej działają normalnie) — tap "przechodzi" do nich plus
                // do tego handler'a paralelnie.
                TapGesture()
                    .onEnded { focusedField = nil }
            )
            .onAppear { send(.viewDidAppear) }
        }
        // Sheet zamyka się WYŁĄCZNIE przez explicit Cancel/Save w toolbar. Swipe-down
        // i tap poza sheet są disabled — user musi świadomie zdecydować save vs anuluj.
        // Zapobiega przypadkowemu zamknięciu sheet'a z wypełnionym formularzem.
        .interactiveDismissDisabled()
    }

    // MARK: - Private views (struktura)

    private var detailsSection: some View {
        Section {
            TextField(nameFieldPlaceholder, text: $store.name)
                .textInputAutocapitalization(.words)
                .focused($focusedField, equals: .name)
                .submitLabel(.next)
                .onSubmit { focusedField = .location }
            TextField(locationFieldPlaceholder, text: $store.location)
                .textInputAutocapitalization(.words)
                .focused($focusedField, equals: .location)
                .submitLabel(.done)
                .onSubmit { focusedField = nil }
        } header: {
            Text(detailsHeader)
        }
    }

    @ViewBuilder
    private var scheduleSection: some View {
        Section {
            Toggle(scheduleToggleLabel, isOn: $store.hasSchedule)
            if store.hasSchedule {
                DatePicker(
                    datePickerLabel,
                    selection: $store.scheduledAt,
                    displayedComponents: [.date, .hourAndMinute]
                )
            }
        } header: {
            Text(scheduleHeader)
        }
    }

    private var capacitySection: some View {
        Section {
            Stepper(
                value: $store.maxParticipants,
                in: GymClassCapacity.lowerBound...store.maxParticipantsUpperBound
            ) {
                HStack {
                    Text(capacityLabel)
                    Spacer()
                    Text("\(store.maxParticipants)")
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
            }
        } header: {
            Text(capacityHeader)
        } footer: {
            capacityFooter
        }
    }

    @ViewBuilder
    private var capacityFooter: some View {
        if store.exceedsDeviceLimit {
            Text(deviceLimitErrorMessage(limit: store.deviceCapacity))
                .foregroundStyle(.red)
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button(cancelTitle) {
                send(.cancelTapped)
            }
        }
        ToolbarItem(placement: .confirmationAction) {
            Button(saveTitle) {
                send(.saveTapped)
            }
            .disabled(!store.isValid)
        }
    }

    /// "Done" button w keyboard toolbar — explicit dismiss klawiatury bez konieczności
    /// tap'nięcia poza Form. Pomocne na iPad gdy Form pokrywa cały sheet (mało
    /// "outside space" do tap'nięcia).
    @ToolbarContentBuilder
    private var keyboardToolbar: some ToolbarContent {
        ToolbarItemGroup(placement: .keyboard) {
            Spacer()
            Button(doneTitle) {
                focusedField = nil
            }
        }
    }

    // MARK: - Private content (implementacja)

    /// "Edit class" w edit mode, "New class" w create mode. Wizualnie sygnalizuje
    /// trenerowi czy modyfikuje istniejący template czy tworzy nowy.
    private var navigationTitle: String {
        if store.editingId != nil {
            String(localized: "Edit class", bundle: .main)
        } else {
            String(localized: "New class", bundle: .main)
        }
    }

    private var detailsHeader: String {
        String(localized: "Details", bundle: .main)
    }

    private var scheduleHeader: String {
        String(localized: "Schedule", bundle: .main)
    }

    private var nameFieldPlaceholder: String {
        String(localized: "Class name", bundle: .main)
    }

    private var locationFieldPlaceholder: String {
        String(localized: "Location (e.g. Sala 1)", bundle: .main)
    }

    private var scheduleToggleLabel: String {
        String(localized: "Set scheduled time", bundle: .main)
    }

    private var datePickerLabel: String {
        String(localized: "Scheduled at", bundle: .main)
    }

    private var saveTitle: String {
        String(localized: "Save", bundle: .main)
    }

    private var cancelTitle: String {
        String(localized: "Cancel", bundle: .main)
    }

    private var doneTitle: String {
        String(localized: "Done", bundle: .main)
    }

    private var capacityHeader: String {
        String(localized: "Capacity", bundle: .main)
    }

    private var capacityLabel: String {
        String(localized: "Max athletes", bundle: .main)
    }

    private func deviceLimitErrorMessage(limit: Int) -> String {
        String(localized: "This device supports up to \(limit) athletes. Reduce the value to save.", bundle: .main)
    }
}

#Preview {
    ClassCreationView(
        store: Store(initialState: ClassCreationFeature.State()) {
            ClassCreationFeature()
        }
    )
}
