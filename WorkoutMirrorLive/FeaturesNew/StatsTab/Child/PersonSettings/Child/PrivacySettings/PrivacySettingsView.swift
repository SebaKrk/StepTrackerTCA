//
//  PrivacySettingsView.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 21/11/2026.
//

import ComposableArchitecture
import SwiftUI

@ViewAction(for: PrivacySettingsFeature.self)
struct PrivacySettingsView: View {

    // MARK: - Properties

    @Bindable var store: StoreOf<PrivacySettingsFeature>

    // MARK: - Body (structure)

    var body: some View {
        List {
            aiSection
            supportSection
            dataSection
        }
        .navigationTitle(Text(title))
        .navigationBarTitleDisplayMode(.inline)
        .alert($store.scope(state: \.alert, action: \.alert))
        .navigationDestination(
            item: $store.scope(state: \.destination?.diagnostics, action: \.destination.diagnostics)
        ) { diagnosticsStore in
            DeveloperSettingsView(store: diagnosticsStore)
        }
    }

    // MARK: - Sections (structure)

    private var aiSection: some View {
        Section {
            aiProcessingToggle
        } header: {
            Text(aiHeader)
        } footer: {
            Text(aiFooter)
        }
    }

    private var supportSection: some View {
        Section {
            diagnosticsRow
        } header: {
            Text(supportHeader)
        } footer: {
            Text(supportFooter)
        }
    }

    private var dataSection: some View {
        Section {
            deleteCloudDataButton
        } header: {
            Text(dataHeader)
        } footer: {
            Text(dataFooter)
        }
    }

    // MARK: - Rows (implementation)

    private var aiProcessingToggle: some View {
        Toggle(isOn: Binding(
            get: { store.isAIProcessingAllowed },
            set: { send(.aiProcessingToggled($0)) }
        )) {
            Text(aiToggleTitle)
        }
        .tint(.green)
    }

    private var diagnosticsRow: some View {
        HStack {
            Image(systemName: "wrench.and.screwdriver.fill")
                .foregroundStyle(.secondary)
            Text(diagnosticsTitle)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            send(.diagnosticsTapped)
        }
    }

    private var deleteCloudDataButton: some View {
        Button(role: .destructive) {
            send(.deleteCloudDataTapped)
        } label: {
            HStack {
                Text(deleteTitle)
                Spacer()
                if store.isDeletingCloudData {
                    ProgressView()
                        .transition(.opacity)
                }
            }
        }
        .disabled(store.isDeletingCloudData)
        .animation(.default, value: store.isDeletingCloudData)
    }

    // MARK: - Text

    private let title = String(localized: "Privacy & data")
    private let aiHeader = String(localized: "AI features")
    private let aiToggleTitle = String(localized: "Board scan and warm-ups with AI")
    private let aiFooter = String(localized: "Scanning a board and generating a warm-up send the plan to Anthropic. We keep no copy. When this is off, the app asks before anything is sent.")
    private let supportHeader = String(localized: "Support")
    private let diagnosticsTitle = String(localized: "Diagnostics")
    private let supportFooter = String(localized: "A diagnostics bundle you can send when something goes wrong.")
    private let dataHeader = String(localized: "Your data")
    private let deleteTitle = String(localized: "Delete my cloud data")
    private let dataFooter = String(localized: "Erases your results, group memberships and account from our server. Workouts in the Health app and plans on this iPhone stay.")
}

// MARK: - Preview

#Preview {
    NavigationStack {
        PrivacySettingsView(
            store: Store(initialState: PrivacySettingsFeature.State()) {
                PrivacySettingsFeature()
            }
        )
    }
}
