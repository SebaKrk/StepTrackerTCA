//
//  ClassHistoryFeature.swift
//  GymRoom
//
//  Created by Sebastian Ściuba on 18/06/2026.
//

import AppDatabase
import ComposableArchitecture
import Foundation
import OSLog
import SharedModels

/// Reducer dla History tab — lista past sessions reverse-chrono.
///
/// **Scope (mini-D)**: tylko list view bez detail push / charts. Pełny detail z
/// wykresami HR przyjdzie w subtask E (`ClassHistoryDetailFeature`).
///
/// **Source of truth**: `gymClassClient.fetchAllSessions()` zwraca wszystkie
/// `classSessionRecords` ORDER BY startedAt DESC.
@Reducer
struct ClassHistoryFeature {

    @Dependency(\.gymClassClient) var gymClassClient

    @ObservableState
    struct State {

        /// Past sessions reverse-chrono. Empty po pierwszym launchu, populated
        /// w `viewDidAppear` przez async fetch.
        var sessions: [ClassSessionRecord] = []
    }

    @CasePathable
    enum Action: ViewAction {

        /// Internal — result `gymClassClient.fetchAllSessions()`.
        case sessionsLoaded([ClassSessionRecord])

        case view(View)

        enum View {
            /// Lifecycle — fetch sessions przy każdym pojawieniu się tab'a History.
            /// `.task` w View triggeruje re-fetch (auto-refresh po wróceniu z innej tab).
            case viewDidAppear
        }
    }

    var body: some Reducer<State, Action> {
        Reduce<State, Action> { state, action in
            switch action {

            case .view(.viewDidAppear):
                return .run { send in
                    let sessions = try await gymClassClient.fetchAllSessions()
                    await send(.sessionsLoaded(sessions))
                } catch: { error, _ in
                    Logger.gymRoom.error("❌ fetchAllSessions failed: \(error.localizedDescription)")
                }

            case let .sessionsLoaded(sessions):
                state.sessions = sessions
                return .none
            }
        }
    }
}
