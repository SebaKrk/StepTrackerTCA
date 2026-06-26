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

        /// Loading state listy sesji — `.loading` na start, `.success` po
        /// `sessionsLoaded`, `.failed` na `fetchFailed`. Bez tego user widzi
        /// "No past classes yet" zanim fetch dojdzie.
        var viewState: ViewState = .loading

        /// Past sessions reverse-chrono. Empty po pierwszym launchu, populated
        /// w `viewDidAppear` przez async fetch.
        var sessions: [ClassSessionRecord] = []

        /// Pushed detail view dla tap'niętej sesji. Nil = lista visible.
        @Presents var detail: ClassHistoryDetailFeature.State?

        /// Confirm alert przed cascade delete sesji (kasuje też athleteSessionRecords).
        @Presents var alert: AlertState<Action.Alert>?

        /// Snapshot sesji do delete — alert `confirmDelete` używa jej id.
        var sessionToDelete: ClassSessionRecord?

        /// Snapshot sesji do force-end — alert `confirmEnd` używa jej id.
        /// Force-end ongoing session (endedAt == nil) gdy WC end-flow zawiódł.
        var sessionToEnd: ClassSessionRecord?
    }

    @CasePathable
    enum Action: ViewAction {

        /// Internal — result `gymClassClient.fetchAllSessions()`.
        case sessionsLoaded([ClassSessionRecord])

        /// `gymClassClient.fetchAllSessions()` rzucił błąd — `viewState = .failed`,
        /// View pokazuje retry placeholder.
        case fetchFailed

        /// Child reducer navigation actions.
        case detail(PresentationAction<ClassHistoryDetailFeature.Action>)

        case alert(PresentationAction<Alert>)

        enum Alert: Equatable {
            /// Trener potwierdził cascade delete sesji + athlete data.
            case confirmDelete

            /// Trener potwierdził force-end ongoing session — `endedAt = .now`,
            /// finalize wszystkich athletes z `leftAt == nil` (analytics computed).
            case confirmEnd
        }

        case view(View)

        enum View {
            /// Lifecycle — fetch sessions przy każdym pojawieniu się tab'a History.
            /// `.task` w View triggeruje re-fetch (auto-refresh po wróceniu z innej tab).
            case viewDidAppear

            /// User tap row → push detail view z sesją snapshot'em.
            case sessionRowTapped(ClassSessionRecord)

            /// User swipe-to-delete row → present alert confirm cascade delete.
            case sessionDeleteTapped(ClassSessionRecord)

            /// User swipe → "End" button na ongoing sesji (endedAt == nil).
            /// Present alert confirm force-end.
            case sessionEndTapped(ClassSessionRecord)
        }
    }

    var body: some Reducer<State, Action> {
        Reduce<State, Action> { state, action in
            switch action {

            case .view(.viewDidAppear):
                state.viewState = .loading
                return .run { send in
                    let sessions = try await gymClassClient.fetchAllSessions()
                    await send(.sessionsLoaded(sessions))
                } catch: { error, send in
                    Logger.gymRoom.error("❌ fetchAllSessions failed: \(error.localizedDescription)")
                    await send(.fetchFailed)
                }

            case let .sessionsLoaded(sessions):
                state.sessions = sessions
                state.viewState = .success
                return .none

            case .fetchFailed:
                state.viewState = .failed
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

            case let .view(.sessionDeleteTapped(session)):
                state.sessionToDelete = session
                state.alert = .deleteSession(session.className)
                return .none

            case let .view(.sessionEndTapped(session)):
                state.sessionToEnd = session
                state.alert = .endSession(session.className)
                return .none

            case .alert(.presented(.confirmDelete)):
                guard let session = state.sessionToDelete else { return .none }
                /// Optimistic remove ze state + cascade delete w bazie.
                state.sessions.removeAll { $0.id == session.id }
                state.sessionToDelete = nil
                return .run { _ in
                    try await gymClassClient.deleteSession(session.id)
                } catch: { error, _ in
                    Logger.gymRoom.error("❌ deleteSession failed: \(error.localizedDescription)")
                }

            case .alert(.presented(.confirmEnd)):
                guard let session = state.sessionToEnd else { return .none }
                let endedAt = Date()
                state.sessionToEnd = nil
                /// Force-end + refetch (ClassSessionRecord ma let'y, najprościej refresh listy).
                return .run { send in
                    try await gymClassClient.endSession(session.id, endedAt)
                    let sessions = try await gymClassClient.fetchAllSessions()
                    await send(.sessionsLoaded(sessions))
                } catch: { error, _ in
                    Logger.gymRoom.error("❌ endSession failed: \(error.localizedDescription)")
                }

            case .alert(.dismiss), .alert:
                state.sessionToDelete = nil
                state.sessionToEnd = nil
                return .none

            case let .detail(.presented(.delegate(.sessionDeleted(id)))):
                /// Detail child skasował sesję z menu ellipsis. Cascade delete już
                /// wykonany w child (gymClassClient). Pop detail + remove ze state.sessions.
                state.detail = nil
                state.sessions.removeAll { $0.id == id }
                return .none

            case .detail:
                return .none
            }
        }
        .ifLet(\.$detail, action: \.detail) {
            ClassHistoryDetailFeature()
        }
        .ifLet(\.$alert, action: \.alert)
    }
}
