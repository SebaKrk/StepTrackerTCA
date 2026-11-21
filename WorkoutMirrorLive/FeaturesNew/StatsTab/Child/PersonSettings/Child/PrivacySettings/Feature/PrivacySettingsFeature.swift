//
//  PrivacySettingsFeature.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 21/11/2026.
//

import ComposableArchitecture
import Foundation
import HealthHub
import SharedModels

/// Everything about data that leaves the phone: the AI consent, the diagnostics bundle and erasing the cloud data.
@Reducer
struct PrivacySettingsFeature {

    // MARK: - Dependency

    @Dependency(\.teamClient) var teamClient
    @Dependency(\.userProfileClient) var userProfileClient

    // MARK: - Reducer

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {

                // MARK: - View Action

            case let .view(.aiProcessingToggled(isAllowed)):
                // Taking the consent back is confirmed first; the switch stays on until then.
                guard isAllowed else {
                    state.alert = .confirmTurnOffAIProcessing
                    return .none
                }
                state.$isAIProcessingAllowed.withLock { $0 = true }
                return .none

            case .view(.diagnosticsTapped):
                state.destination = .diagnostics(DeveloperSettingsFeature.State())
                return .none

            case .view(.deleteCloudDataTapped):
                guard !state.isDeletingCloudData else { return .none }
                state.alert = .confirmDeleteCloudData
                return .none

                // MARK: - Internal Action

            case .cloudDataDeleted(.success):
                state.isDeletingCloudData = false
                state.alert = .cloudDataDeleted
                return .none

            case let .cloudDataDeleted(.failure(error)):
                state.isDeletingCloudData = false
                state.alert = .cloudDataDeletionFailed(Self.deletionFailureMessage(for: error))
                return .none

                // MARK: - Alert

            case .alert(.presented(.aiProcessingTurnOffConfirmed)):
                state.$isAIProcessingAllowed.withLock { $0 = false }
                return .none

            case .alert(.presented(.deleteCloudDataConfirmed)):
                state.isDeletingCloudData = true
                return .run { [teamClient, userProfileClient] send in
                    await send(.cloudDataDeleted(Result {
                        try await teamClient.deleteMyData()
                        // The stored id points at an account that no longer exists.
                        guard var profile = try await userProfileClient.fetch() else { return }
                        profile.accountUid = ""
                        try await userProfileClient.save(profile)
                    }))
                }

            case .alert:
                return .none

            case .destination:
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination) {
            Destination.body
        }
        .ifLet(\.$alert, action: \.alert)
    }

    // MARK: - Helpers

    /// The shared proxy copy speaks of scans and photos; an erase needs sentences of its own.
    private static func deletionFailureMessage(for error: any Error) -> String {
        if case ScanProxyError.network = error {
            return String(localized: "Make sure you have a stable internet connection and try again.")
        }
        return String(localized: "The server did not finish the erase. Nothing is assumed gone — try again in a moment.")
    }
}
