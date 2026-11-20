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
                state.diagnosticsMailURL = nil
                state.diagnosticsShareURL = nil
                return .none

            }
        }
    }
}
