//
//  APIKeyEntryFeature.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 12/02/2026.
//

import ComposableArchitecture
import Foundation

@Reducer
struct APIKeyEntryFeature {

    // MARK: - State

    @ObservableState
    struct State {
        /// Draft key typed by the user (empty when key already exists).
        var draftKey: String = ""
        /// Whether a key is already stored in Keychain.
        var hasExistingKey: Bool
        /// Whether this screen is presented as a sheet (true) or via navigation (false).
        var isPresentedAsSheet: Bool = true
    }

    // MARK: - Action

    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case saveButtonTapped
        case deleteKeyTapped
        case cancelTapped
        case delegate(Delegate)

        enum Delegate {
            case keySaved
            case keyDeleted
        }
    }

    // MARK: - Dependencies

    @Dependency(\.apiKeyClient) var apiKeyClient
    @Dependency(\.dismiss) var dismiss

    // MARK: - Body

    var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce { state, action in
            switch action {

            case .saveButtonTapped:
                let key = state.draftKey.trimmingCharacters(in: .whitespaces)
                guard !key.isEmpty else { return .none }
                apiKeyClient.save(key)
                return .send(.delegate(.keySaved))
                // Parent dismisses via state.apiKeyEntry = nil

            case .deleteKeyTapped:
                apiKeyClient.delete()
                return .send(.delegate(.keyDeleted))
                // Parent dismisses via state.apiKeyEntry = nil

            case .cancelTapped:
                return .run { _ in await dismiss() }

            case .binding, .delegate:
                return .none
            }
        }
    }
}
