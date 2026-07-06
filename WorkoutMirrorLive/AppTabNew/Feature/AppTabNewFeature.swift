//
//  AppTabNewFeature.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 20/08/2025.
//

import ComposableArchitecture
import Foundation
import OSLog
import SharedModels

@Reducer
struct AppTabNewFeature {

    // MARK: - Dependencies

    @Dependency(\.watchConnectivityClient) var watchConnectivityClient
    @Dependency(\.workoutPlanScoreClient) var workoutPlanScoreClient
    @Dependency(\.uuid) var uuid
    @Dependency(\.date.now) var now

    // MARK: - Reducer

    var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce<State, Action> { state, action in
            switch action {
                // MARK: - Binding
            case .binding(_):
                return .none
                
                // MARK: - Action
            case let .tabChanged(tab):
                if tab == .workout {
                    return .send(.activateWorkoutView)
                } else {
                    state.selectedTab = tab
                    return .none
                }
                
            case .activateWorkoutView:
                //state.destination = .workout(WorkoutFeature.State())
                state.destination = .workoutConfiguration(ConfigurationFeature.State())
                return .none
                
            case let .activateWorkoutSessionView(workout):
                state.destination = .session(SessionFeature.State(selectedWorkout: workout))
                return .none
                
                // MARK: - View Action
            case .view(.viewDidAppear):
                // App-level listener — `.workoutSaved` must be consumed regardless of
                // which screen is open (SessionFeature may be long dismissed when
                // `transferUserInfo` delivers the event, even on a later app launch).
                return .run { [watchClient = watchConnectivityClient] send in
                    for await event in watchClient.incomingEventStream() {
                        guard case let .workoutSaved(workoutUUID) = event else { continue }
                        await send(.workoutSavedEventReceived(workoutUUID))
                    }
                }
                .cancellable(id: AppTabNewCancelID.watchSavedEventListener, cancelInFlight: true)

            case let .workoutSavedEventReceived(workoutId):
                // The list/badge refresh happens without our involvement: the list observes
                // HealthKit (observeWorkoutChanges), the badge observes the database (@FetchAll).
                // Only persisting the plan↔workout link remains here.
                return .run { [scoreClient = workoutPlanScoreClient, uuid, now] _ in
                    @Shared(.pendingPlanLink) var pendingPlanLink
                    guard let pending = pendingPlanLink else { return }

                    // Staleness guard — a pending link from an abandoned start must not
                    // claim an unrelated workout saved hours later.
                    guard now.timeIntervalSince(pending.workoutStartDate) < Self.pendingLinkMaxAge else {
                        $pendingPlanLink.withLock { $0 = nil }
                        Logger.session.notice("pendingPlanLink stale — dropped without linking")
                        return
                    }

                    // Idempotency — duplicate event delivery (sendMessage + transferUserInfo
                    // fallback) or an already-existing score must not be overwritten.
                    guard try await scoreClient.fetchByHKWorkoutId(workoutId) == nil else {
                        $pendingPlanLink.withLock { $0 = nil }
                        return
                    }

                    let score = WorkoutPlanScore(
                        id: uuid(),
                        date: pending.workoutStartDate,
                        trainingSessionId: pending.trainingSessionId,
                        hkWorkoutId: workoutId,
                        results: []
                    )
                    try await scoreClient.save(score)
                    $pendingPlanLink.withLock { $0 = nil }
                    Logger.session.info("plan↔workout linked — plan \(pending.trainingSessionId), workout \(workoutId)")
                    await WorkoutFileLogger.shared.log("[PlanLink] linked plan \(pending.trainingSessionId) ↔ workout \(workoutId)")
                } catch: { error, _ in
                    Logger.session.error("plan↔workout link failed: \(error.localizedDescription)")
                }

                // MARK: - Destination
            case let .destination(.presented(.workoutConfiguration(.delegate(.start(workout))))):
                return .run { send in
                    await send(.activateWorkoutSessionView(workout))
                }

            case .destination:
                return .none
                
            default:
                return .none
            }
        }
        
        Scope(state: \.stats, action: \.stats) {
            StatsFeature()
        }
        Scope(state: \.activities, action: \.activities) {
            ActivitiesFeature()
        }
        .ifLet(\.$destination, action: \.destination)
    }
}

extension AppTabNewFeature {

    /// Maximum age of a pending plan link at consume time. Older entries come from
    /// abandoned starts (workout never saved) and must not claim unrelated workouts.
    static let pendingLinkMaxAge: TimeInterval = 12 * 3600
}

/// Cancel identifiers used by `AppTabNewFeature` long-running effects.
///
/// `nonisolated` — see `SessionWatchCancelID` for rationale (project-wide
/// `defaultIsolation(MainActor.self)` vs `cancellable(id:)` Sendable requirement).
nonisolated enum AppTabNewCancelID: Hashable, Sendable {

    /// App-lifetime listener for `.workoutSaved` events from Watch (IOS-00098-C).
    /// Started on root `viewDidAppear`; `cancelInFlight` guards against duplicate
    /// listeners on view re-appear.
    case watchSavedEventListener
}

/// Implementation of `AppTabNewFeature` action
extension AppTabNewFeature {
    
    @CasePathable
    enum Action: ViewAction, BindableAction {
        
        // MARK: - Binding Action
        
        /// Handles changes in bindings for the state.
        case binding(BindingAction<State>)
        
        // MARK: - Actions
        
        /// Action triggered when the user changes the selected tab.
        case tabChanged(AppScreen)
        
        ///
        case activateWorkoutView
        
        ///
        case activateWorkoutSessionView(WorkoutType)

        /// Watch reported a saved `HKWorkout` (`.workoutSaved` via WatchConnectivity).
        /// Consumes the pending plan link and writes an empty-results score record (IOS-00098-C).
        case workoutSavedEventReceived(UUID)
        
        // MARK: - View Actions
        
        case view(View)
        
        enum View {

            /// Action triggered when the view appears on the screen.
            case viewDidAppear
        }
        
        // MARK: - Child
        
        ///
        case stats(StatsFeature.Action)

        ///
        case activities(ActivitiesFeature.Action)
        
        // MARK: - Destination
        
        /// Action to handle navigation destinations within this feature.
        case destination(PresentationAction<Destination.Action>)
    }
}

/// Implementation of `AppTabNewFeature` state
extension AppTabNewFeature {
    
    @ObservableState
    struct State {
        
        // MARK: - Properties
        
        /// List of available tabs in the application.
        ///
        /// The order of tabs determines their placement in the UI.
        var tabs: [AppScreen] = [.stats, .activities, .workout]
        
        /// The currently selected tab in the application.
        ///
        /// Default value is `.summary`.
        var selectedTab: AppScreen = .stats
        
        // MARK: - Child
        
        ///
        var stats: StatsFeature.State = .init()
        
        ///
        var activities: ActivitiesFeature.State = .init()
        
        // MARK: - Destination
        
        /// destination from WorkoutFeature
        @Presents var destination: Destination.State?
    }
    
}

/// Implementation of `AppTabNewFeature` destination
extension AppTabNewFeature {
    
    @Reducer
    enum Destination {

        /// Represents the destination for displaying in `ConfigurationFeature`.
        case workoutConfiguration(ConfigurationFeature)

        /// Represents the destination for displaying in `WorkoutSessionFeature`.
        //case session(WorkoutSessionFeature)
        case session(SessionFeature)
    }
}

