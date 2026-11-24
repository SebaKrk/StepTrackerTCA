//
//  DeveloperSettingsFeature.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 14/11/2026.
//

import ComposableArchitecture
import Foundation
import IssueReporting

@Reducer
struct DeveloperSettingsFeature {

    // MARK: - Dependency

    @Dependency(\.diagnosticsClient) var diagnosticsClient

    @Dependency(\.watchConnectivityClient) var watchConnectivityClient

    @Dependency(\.workoutLogClient) var workoutLogClient

    // MARK: - Reducer

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {

                // MARK: - Action
            case let .diagnosticsBundleReady(url):
                state.isBuildingDiagnostics = false

                guard let url else { return .none }

                // A device with no mail account opens nothing at all, so the
                // share sheet stands in and the footer carries the address.
                if diagnosticsClient.canSendMail() {
                    state.diagnosticsMailURL = url
                } else {
                    state.diagnosticsShareURL = url
                }

                return .none

                // MARK: - View Action
            case .view(.includeDatabaseToggled):
                state.includesDatabaseInDiagnostics.toggle()
                return .none

            case .view(.recordWorkoutLogsToggled):
                guard !state.isWorkoutLogRecordingForced, !state.isBuildingDiagnostics else { return .none }
                let isRecording = !state.isRecordingWorkoutLogs
                state.$isRecordingWorkoutLogs.withLock { $0 = isRecording }

                return .run { [diagnosticsClient, workoutLogClient, watchConnectivityClient] _ in
                    // Switching off is a promise that nothing stays behind, on either device.
                    if !isRecording {
                        await workoutLogClient.removeAll()
                        diagnosticsClient.discardBundles()
                    }
                    await watchConnectivityClient.publishWorkoutLogRecording(isRecording)
                }

            case .view(.sendDiagnosticsTapped):
                guard !state.isBuildingDiagnostics else { return .none }
                state.isBuildingDiagnostics = true

                let includesDatabase = state.includesDatabaseInDiagnostics

                return .run { [diagnosticsClient] send in
                    let url = try await diagnosticsClient.makeBundle(includesDatabase)
                    await send(.diagnosticsBundleReady(url))
                } catch: { error, send in
                    reportIssue(error)
                    await send(.diagnosticsBundleReady(nil))
                }

            case .view(.diagnosticsDeliveryDismissed):
                let wasMailed = state.diagnosticsMailURL != nil
                state.diagnosticsMailURL = nil
                state.diagnosticsShareURL = nil

                // The composer already holds the archive in memory; a share target may still be reading the file.
                guard wasMailed else { return .none }

                return .run { [diagnosticsClient] _ in
                    diagnosticsClient.discardBundles()
                }

            }
        }
    }
}
