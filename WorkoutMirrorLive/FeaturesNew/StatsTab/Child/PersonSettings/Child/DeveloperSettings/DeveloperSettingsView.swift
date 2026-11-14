//
//  DeveloperSettingsView.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 14/11/2026.
//

import ComposableArchitecture
import SwiftUI

@ViewAction(for: DeveloperSettingsFeature.self)
struct DeveloperSettingsView: View {

    // MARK: - Properties

    @Bindable var store: StoreOf<DeveloperSettingsFeature>

    // MARK: - Body

    var body: some View {
        rootView
            .navigationTitle(Text(String(localized: "Developer")))
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(
                item: $store.scope(state: \.destination?.apiKey, action: \.destination.apiKey)
            ) { apiKeyStore in
                APIKeyEntryView(store: apiKeyStore)
            }
            .sheet(isPresented: isSendingMail) {
                diagnosticsMailComposer
            }
            .sheet(isPresented: isSharingDiagnostics) {
                diagnosticsShareSheet
            }
    }

    // MARK: - SubView

    private var rootView: some View {
        List {
            apiKeySection
            diagnosticsSection
            sendDiagnosticsSection
        }
    }

    private var apiKeySection: some View {
        Section {
            apiKeyRow
        } footer: {
            Text(String(localized: "Manage API keys for AI-powered workout parsing and analysis."))
        }
    }

    private var apiKeyRow: some View {
        HStack {
            Image(systemName: "key.fill")
                .foregroundStyle(.secondary)
            Text(String(localized: "API Key"))
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            send(.apiKeyTapped)
        }
    }

    private var diagnosticsSection: some View {
        Section {
            attachDatabaseToggle
        } header: {
            Text(String(localized: "Diagnostics"))
        } footer: {
            Text(diagnosticsFooterText)
                .animation(.default, value: store.includesDatabaseInDiagnostics)
        }
    }

    /// Its own section, the way Settings separates an action from the switches
    /// that configure it.
    private var sendDiagnosticsSection: some View {
        Section {
            sendDiagnosticsRow
        } footer: {
            Text(String(localized: "Sent to \(DiagnosticsRecipient.address)."))
        }
    }

    private var attachDatabaseToggle: some View {
        Toggle(isOn: attachesDatabase) {
            Text(String(localized: "Attach database"))
        }
        .tint(.green)
    }

    /// An action, not a destination — so no chevron, and a real `Button` rather
    /// than a tap gesture, which VoiceOver would never announce as tappable.
    private var sendDiagnosticsRow: some View {
        Button {
            send(.sendDiagnosticsTapped)
        } label: {
            HStack {
                Spacer()
                Text(String(localized: "Send diagnostics"))
                Spacer()
            }
            .overlay(alignment: .trailing) {
                if store.isBuildingDiagnostics {
                    ProgressView()
                }
            }
        }
        .disabled(store.isBuildingDiagnostics)
    }

    // MARK: - Sheets

    @ViewBuilder
    private var diagnosticsMailComposer: some View {
        if let url = store.diagnosticsMailURL {
            DiagnosticsMailComposer(url: url) {
                send(.diagnosticsDeliveryDismissed)
            }
        }
    }

    @ViewBuilder
    private var diagnosticsShareSheet: some View {
        if let url = store.diagnosticsShareURL {
            DiagnosticsShareSheet(url: url) {
                send(.diagnosticsDeliveryDismissed)
            }
        }
    }

    // MARK: - Bindings

    private var attachesDatabase: Binding<Bool> {
        Binding(
            get: { store.includesDatabaseInDiagnostics },
            set: { _ in send(.includeDatabaseToggled) }
        )
    }

    /// Presented only once an archive exists, so the composer never opens empty.
    private var isSendingMail: Binding<Bool> {
        Binding(
            get: { store.diagnosticsMailURL != nil },
            set: { isPresented in
                guard !isPresented else { return }
                send(.diagnosticsDeliveryDismissed)
            }
        )
    }

    private var isSharingDiagnostics: Binding<Bool> {
        Binding(
            get: { store.diagnosticsShareURL != nil },
            set: { isPresented in
                guard !isPresented else { return }
                send(.diagnosticsDeliveryDismissed)
            }
        )
    }

    // MARK: - Text

    /// Says plainly what the next bundle will carry, because the two answers
    /// differ by a whole training history.
    private var diagnosticsFooterText: String {
        store.includesDatabaseInDiagnostics
            ? String(localized: "The bundle will carry your full training history and your profile.")
            : String(localized: "The bundle describes the app only — versions, migrations and row counts. No training data leaves the device.")
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        DeveloperSettingsView(
            store: Store(initialState: DeveloperSettingsFeature.State()) {
                DeveloperSettingsFeature()
            }
        )
    }
}
