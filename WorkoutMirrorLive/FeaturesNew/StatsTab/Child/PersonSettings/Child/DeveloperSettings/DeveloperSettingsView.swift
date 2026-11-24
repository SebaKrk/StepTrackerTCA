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
            .navigationTitle(Text(String(localized: "Diagnostics")))
            .navigationBarTitleDisplayMode(.inline)
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
            workoutLogsSection
            diagnosticsSection
            sendDiagnosticsSection
        }
    }

    private var workoutLogsSection: some View {
        Section {
            recordWorkoutLogsToggle
        } header: {
            Text(String(localized: "Workout logs"))
        } footer: {
            Text(workoutLogsFooterText)
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
                .animation(.default, value: store.attachesWorkoutLogs)
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

    private var recordWorkoutLogsToggle: some View {
        Toggle(isOn: recordsWorkoutLogs) {
            Text(String(localized: "Record workout logs"))
        }
        .tint(.green)
        // Switching off sweeps the temporary folder, which would pull a bundle being built from under it.
        .disabled(store.isWorkoutLogRecordingForced || store.isBuildingDiagnostics)
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

    private var recordsWorkoutLogs: Binding<Bool> {
        Binding(
            get: { store.attachesWorkoutLogs },
            set: { _ in send(.recordWorkoutLogsToggled) }
        )
    }

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

    /// Says what is recorded, for how long, and that switching off deletes it.
    private var workoutLogsFooterText: String {
        String(localized: "Records workout and connection events on this iPhone and on Apple Watch, with heart rate every 30 seconds. Logs are kept for 7 days and leave the device only with diagnostics. Turning this off deletes them.")
    }

    /// Says plainly what the next bundle will carry, because the two answers
    /// differ by a whole training history.
    private var diagnosticsFooterText: String {
        if store.includesDatabaseInDiagnostics {
            return String(localized: "The bundle will carry your full training history and your profile.")
        }
        if store.attachesWorkoutLogs {
            return String(localized: "The bundle describes the app — versions, migrations and row counts — and carries your workout logs, heart rate included.")
        }
        return String(localized: "The bundle describes the app only — versions, migrations and row counts. No training data leaves the device.")
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
