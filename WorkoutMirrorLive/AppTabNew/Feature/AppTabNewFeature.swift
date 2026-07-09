//
//  AppTabNewFeature.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 20/08/2025.
//

import ComposableArchitecture
import Foundation
import HealthHub
import OSLog
import SharedModels

@Reducer
struct AppTabNewFeature {

    // MARK: - Dependencies

    @Dependency(\.watchConnectivityClient) var watchConnectivityClient
    @Dependency(\.workoutPlanScoreClient) var workoutPlanScoreClient
    @Dependency(\.effortScoreClient) var effortScoreClient
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
                
            case let .activateWorkoutSessionView(workout, device):
                state.destination = .session(SessionFeature.State(selectedWorkout: workout, requestedDevice: device))
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
                // Two things remain: persist the plan↔workout link, and freeze the effort
                // points captured live at workout end against this HKWorkout.
                return .merge(
                    .send(.persistEffortScore(workoutId)),
                    persistPlanLinkEffect(workoutId: workoutId)
                )

            case let .persistEffortScore(workoutId):
                // Link the pending effort snapshot (frozen at session end) to the saved
                // workout. No computation here — the value came from the live accumulator.
                // Fire-and-forget: a failure must not affect the plan-link flow.
                return .run { [effortScoreClient, uuid, now] _ in
                    @Shared(.pendingEffortScore) var pendingEffortScore
                    guard let pending = pendingEffortScore else { return }

                    // Staleness guard — a snapshot from an abandoned start must not
                    // attach to an unrelated workout saved much later.
                    guard now.timeIntervalSince(pending.workoutStartDate) < Self.pendingLinkMaxAge else {
                        $pendingEffortScore.withLock { $0 = nil }
                        Logger.session.notice("pendingEffortScore stale — dropped without saving")
                        return
                    }

                    // Idempotency — duplicate `.workoutSaved` delivery must not double-write.
                    guard try await effortScoreClient.fetchByHKWorkoutId(workoutId) == nil else {
                        $pendingEffortScore.withLock { $0 = nil }
                        return
                    }

                    let score = WorkoutEffortScore(
                        id: uuid(),
                        hkWorkoutId: workoutId,
                        points: pending.points,
                        workoutStartDate: pending.workoutStartDate,
                        secondsByZone: pending.secondsByZone,
                        weightsVersion: pending.weightsVersion
                    )
                    try await effortScoreClient.save(score)
                    $pendingEffortScore.withLock { $0 = nil }
                    Logger.session.info("effort points saved — workout \(workoutId), \(pending.points) pts")
                } catch: { error, _ in
                    // Clear the snapshot even on failure so it can't linger and attach
                    // to an unrelated workout saved later within the staleness window.
                    @Shared(.pendingEffortScore) var pendingEffortScore
                    $pendingEffortScore.withLock { $0 = nil }
                    Logger.session.error("persistEffortScore failed: \(error.localizedDescription)")
                }

                // MARK: - Destination
            case let .destination(.presented(.workoutConfiguration(.delegate(.start(workout, device))))):
                return .run { send in
                    await send(.activateWorkoutSessionView(workout, device))
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

    /// Persists the plan↔workout link for a just-saved workout, consuming the
    /// pending link set at session start. No-op when there is no pending link.
    /// Extracted so `.workoutSavedEventReceived` can run it alongside effort-score
    /// computation without one failing the other.
    private func persistPlanLinkEffect(workoutId: UUID) -> Effect<Action> {
        .run { [scoreClient = workoutPlanScoreClient, uuid, now] _ in
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
    }
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
        case activateWorkoutSessionView(WorkoutType, DeviceOption?)

        /// Watch reported a saved `HKWorkout` (`.workoutSaved` via WatchConnectivity).
        /// Consumes the pending plan link and writes an empty-results score record (IOS-00098-C).
        case workoutSavedEventReceived(UUID)

        /// Freeze the pending effort points snapshot against a saved workout
        /// (IOS-00099-F5). No computation — the value was captured live at session
        /// end. Split from the plan-link flow so neither failure blocks the other.
        case persistEffortScore(UUID)
        
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

