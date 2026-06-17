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

    var body: some View {
        NavigationStack {
            Form {
                detailsSection
                scheduleSection
                capacitySection
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .onAppear { send(.viewDidAppear) }
        }
    }

    // MARK: - Private views (struktura)

    private var detailsSection: some View {
        Section {
            TextField(nameFieldPlaceholder, text: $store.name)
                .textInputAutocapitalization(.words)
            TextField(locationFieldPlaceholder, text: $store.location)
                .textInputAutocapitalization(.words)
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

    // MARK: - Private content (implementacja)

    private var navigationTitle: String {
        String(localized: "New class", bundle: .main)
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
