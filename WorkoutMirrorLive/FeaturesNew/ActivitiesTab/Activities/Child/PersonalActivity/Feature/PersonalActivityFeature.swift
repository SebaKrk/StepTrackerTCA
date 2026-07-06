//
//  PersonalActivityFeature.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 01/02/2026.
//

import ComposableArchitecture
import Foundation
import HealthHub
import HealthKit
import IssueReporting
import SharedModels

@Reducer
struct PersonalActivityFeature {

    // MARK: - Dependency

    @Dependency(\.activityClient) var activityClient
    @Dependency(\.maxHeartRateClient) var maxHeartRateClient

    // MARK: - Reducer
    
    var body: some Reducer<State, Action> {
        Reduce<State, Action> { state, action in
            switch action {
                
                // MARK: - Action
                
            case let .changeViewState(value):
                state.viewState = value
                return .none
                
            case .fetchWorkouts:
                let days = state.days
                let descriptors = state.sortDescriptors
                return .run { send in
                    await send(.workoutsFetched(
                        Result {
                            try await activityClient.fetchWorkouts(days, descriptors)
                        }
                    ))
                }
                // cancelInFlight: a new fetch (observer burst, filter change) kills the ENTIRE
                // previous pipeline (fetch → maxHR → zones) — without this, parallel
                // runs flickered badges and could complete in the wrong order
                // (review cluster E).
                .cancellable(id: PersonalActivityCancelID.fetchPipeline, cancelInFlight: true)

            case let .workoutsFetched(.success(workouts)):
                state.workouts = workouts
                state.zoneInfo = [:]
                state.maxHRByWorkout = [:]

                guard !workouts.isEmpty else {
                    return .send(.allWorkoutZonesAnalyzed([:]))
                }

                return .run { [maxHeartRateClient] send in
                    var maxHRMap: [UUID: Double] = [:]
                    await withTaskGroup(of: (UUID, Double).self) { group in
                        for workout in workouts {
                            group.addTask {
                                let maxHR = await maxHeartRateClient.forWorkout(workout)
                                return (workout.uuid, maxHR)
                            }
                        }
                        for await (workoutID, maxHR) in group {
                            maxHRMap[workoutID] = maxHR
                        }
                    }
                    await send(.maxHRByWorkoutResolved(maxHRMap))
                }
                // Pipeline stage — same ID as the fetch (without cancelInFlight): a new fetch
                // also kills this stage if it is in flight.
                .cancellable(id: PersonalActivityCancelID.fetchPipeline)

            case let .maxHRByWorkoutResolved(map):
                state.maxHRByWorkout = map
                let workouts = state.workouts

                guard !workouts.isEmpty else {
                    return .send(.allWorkoutZonesAnalyzed([:]))
                }

                return .run { [activityClient] send in
                    var zoneResults: [UUID: PrimaryZoneInfo] = [:]
                    await withTaskGroup(of: (UUID, PrimaryZoneInfo?).self) { group in
                        for workout in workouts {
                            let maxHR = map[workout.uuid] ?? 190
                            group.addTask {
                                let zoneInfo = try? await activityClient.analyzeWorkoutZones(workout, maxHR)
                                return (workout.uuid, zoneInfo)
                            }
                        }
                        for await (workoutID, zoneInfo) in group {
                            if let zoneInfo {
                                zoneResults[workoutID] = zoneInfo
                            }
                        }
                    }
                    await send(.allWorkoutZonesAnalyzed(zoneResults))
                }
                .cancellable(id: PersonalActivityCancelID.fetchPipeline)
                
            case let .workoutsFetched(.failure(error)):
                dump(error)
                return .send(.changeViewState(.failed))
                
            case let .allWorkoutZonesAnalyzed(zoneInfo):
                state.zoneInfo = zoneInfo
                return .send(.changeViewState(.success))
                
                // MARK: - View Action
                
            case .view(.viewDidAppear):
                return .merge(
                    .send(.fetchWorkouts),
                    // Push-based refresh (R5): HealthKit itself signals a change in the workout
                    // collection (e.g. Watch→iPhone sync arrived after a finished workout) —
                    // the list refreshes without polling and without user action.
                    .run { [activityClient] send in
                        for await _ in activityClient.observeWorkoutChanges() {
                            await send(.workoutStoreChanged)
                        }
                    }
                    .cancellable(id: PersonalActivityCancelID.workoutChangesObserver, cancelInFlight: true)
                )

            case .workoutStoreChanged:
                // Debounce (review cluster E): an emission burst (multi-workout sync) restarts
                // the 500 ms counter — the pipeline starts ONCE, after the changes settle.
                return .run { send in
                    try? await Task.sleep(for: .milliseconds(500))
                    await send(.fetchWorkouts)
                }
                .cancellable(id: PersonalActivityCancelID.observerDebounce, cancelInFlight: true)
                
            case let .view(.changeDays(value)):
                state.days = value
                state.viewState = .loading
                return .send(.fetchWorkouts)
                
            case let .view(.changeSortOption(value)):
                state.sortDescriptors = value
                state.viewState = .loading
                return .send(.fetchWorkouts)
                
            case let .view(.openDetails(workout)):
                state.destination = .activityDetails(
                    ActivityDetailsFeature.State(
                        workout: workout,
                        maxHeartRate: state.maxHRByWorkout[workout.uuid] ?? 190,
                        primaryZoneInfo: state.zoneInfo[workout.uuid]
                    )
                )
                return .none
                
            case let .view(.showZoneInfo(zone)):
                state.destination = .zoneInfo(
                    HeartRateZoneInfoFeature.State(
                        selectedZone: zone,
                        descriptionIsExpanded: true,
                        displayMode: .singleZone(zone)
                    )
                )
                return .none

            case .view(.refresh):
                return .send(.fetchWorkouts)

            case let .view(.deleteWorkoutSwiped(workout)):
                state.workoutToDelete = workout
                state.deleteAlert = .deleteWorkout
                return .none

            case .alert(.presented(.confirmDelete)):
                let workout = state.workoutToDelete
                state.workoutToDelete = nil
                return .run { [activityClient] send in
                    if let workout {
                        do {
                            try await activityClient.deleteWorkout(workout)
                            await send(.fetchWorkouts)
                        } catch {
                            await send(.deleteFailed)
                        }
                    }
                }

            case .alert(.dismiss):
                state.workoutToDelete = nil
                return .none

            case .deleteFailed:
                state.errorAlert = .cannotDelete
                return .none

            case .errorAlert:
                return .none

                // MARK: - Destination

            case .destination:
                // The "Uzupełnij wyniki" badge updates itself — `pendingScores` is an
                // observed SQLiteData query, saving results in details/Summary
                // lands here without a manual refetch.
                return .none
            }
        }
        .ifLet(\.$deleteAlert, action: \.alert)
        .ifLet(\.$errorAlert, action: \.errorAlert)
        .ifLet(\.$destination, action: \.destination)
    }

}

// MARK: - Cancel IDs

/// Cancel identifiers used by `PersonalActivityFeature` long-running effects.
///
/// `nonisolated` — see `SessionWatchCancelID` for rationale (project-wide
/// `defaultIsolation(MainActor.self)` vs `cancellable(id:)` Sendable requirement).
nonisolated enum PersonalActivityCancelID: Hashable, Sendable {

    /// HealthKit workout-collection observer (R5 push refresh). Lives as long as the
    /// list feature; started on `viewDidAppear`, `cancelInFlight` guards re-appear
    /// duplicates.
    case workoutChangesObserver

    /// 500 ms debounce between an observer emission and the actual fetch —
    /// collapses multi-workout sync bursts into a single pipeline run.
    case observerDebounce

    /// The whole fetch pipeline (fetch → per-workout maxHR → zone analysis).
    /// A new `fetchWorkouts` cancels any in-flight stage (`cancelInFlight` on the
    /// first stage), preventing interleaved snapshots and badge flicker.
    case fetchPipeline
}

