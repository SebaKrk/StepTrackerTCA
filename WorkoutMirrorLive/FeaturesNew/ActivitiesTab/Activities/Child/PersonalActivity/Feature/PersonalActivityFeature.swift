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
                    // Push-based refresh (R5): HealthKit sam sygnalizuje zmianę kolekcji
                    // workoutów (np. sync Watch→iPhone dojechał po zakończonym treningu) —
                    // lista odświeża się bez pollingu i bez akcji usera.
                    .run { [activityClient] send in
                        for await _ in activityClient.observeWorkoutChanges() {
                            await send(.fetchWorkouts)
                        }
                    }
                    .cancellable(id: PersonalActivityCancelID.workoutChangesObserver, cancelInFlight: true)
                )
                
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
                // Badge "Uzupełnij wyniki" aktualizuje się sam — `planScores` to
                // obserwowana query SQLiteData, zapis wyników w details/Summary
                // trafia tu bez ręcznego refetchu.
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

    /// App-lifetime HealthKit workout-collection observer (R5 push refresh).
    /// Started on `viewDidAppear`; `cancelInFlight` guards re-appear duplicates.
    case workoutChangesObserver
}

