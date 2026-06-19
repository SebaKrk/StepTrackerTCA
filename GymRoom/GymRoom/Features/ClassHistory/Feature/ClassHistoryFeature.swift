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

/// Reducer dla History tab — lista past sessions reverse-chrono + push do detail.
///
/// **Source of truth**: `gymClassClient.fetchAllSessions()` zwraca wszystkie
/// `classSessionRecords` ORDER BY startedAt DESC.
///
/// **Navigation**: tap row → `@Presents` child `ClassHistoryDetailFeature` z 4
/// sekcjami charts (top stats, HR per athlete/combined, calories bar, zones pie).
@Reducer
struct ClassHistoryFeature {

    @Dependency(\.gymClassClient) var gymClassClient

    @ObservableState
    struct State {

        /// Past sessions reverse-chrono. Empty po pierwszym launchu, populated
        /// w `viewDidAppear` przez async fetch.
        var sessions: [ClassSessionRecord] = []

        /// Pushed detail view dla tap'niętej sesji. Nil = lista visible.
        @Presents var detail: ClassHistoryDetailFeature.State?
    }

    @CasePathable
    enum Action: ViewAction {

        /// Internal — result `gymClassClient.fetchAllSessions()`.
        case sessionsLoaded([ClassSessionRecord])

        /// Child reducer navigation actions.
        case detail(PresentationAction<ClassHistoryDetailFeature.Action>)

        case view(View)

        enum View {
            /// Lifecycle — fetch sessions przy każdym pojawieniu się tab'a History.
            /// `.task` w View triggeruje re-fetch (auto-refresh po wróceniu z innej tab).
            case viewDidAppear

            /// User tap row → push detail view z sesją snapshot'em.
            case sessionRowTapped(ClassSessionRecord)
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

            case let .view(.sessionRowTapped(session)):
                state.detail = ClassHistoryDetailFeature.State(
                    sessionId: session.id,
                    className: session.className,
                    location: session.location,
                    startedAt: session.startedAt,
                    endedAt: session.endedAt
                )
                return .none

            case .detail:
                return .none
            }
        }
        .ifLet(\.$detail, action: \.detail) {
            ClassHistoryDetailFeature()
        }
    }
}
