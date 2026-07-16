//
//  ActivityDetailsFeature.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 26/12/2025.
//

import ComposableArchitecture
import Foundation
import HealthHub
import SharedModels
import SwiftUI
import HealthKit

/// Coordinator of the Activity Details screen. The data domains live in child
/// features (`HeartRateZones`, `PerformanceMetrics`, `WorkoutRoute`,
/// `ClassRecap`, `ActivityPlanScore`); the parent owns the destinations, the
/// manual-entry flow and the cross-domain orchestration: the recap↔route
/// mutual exclusion and the recap-map gate (IOS-00105).
@Reducer
struct ActivityDetailsFeature {

    // MARK: - Dependency

    @Dependency(\.healthStore) var healthStore
    @Dependency(\.trainingSessionClient) var trainingSessionClient
    @Dependency(\.continuousClock) var clock

    // MARK: - Reducer

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {

                // MARK: - Manual entry

            case let .internal(.manualSummaryLoaded(summary, trainingSession, hrBuffer)):
                state.destination = .summary(.manualEntry(
                    summary: summary,
                    trainingSession: trainingSession,
                    hrBuffer: hrBuffer
                ))
                return .none

            case .internal(.manualSummaryLoadFailed):
                // TODO: alert userowi. Na razie silent fail — TemplatePicker już dismissed.
                return .none

            case let .internal(.editScoreLoaded(summary, trainingSession, hrBuffer, existingResults)):
                state.destination = .summary(.manualEntry(
                    summary: summary,
                    trainingSession: trainingSession,
                    hrBuffer: hrBuffer,
                    existingResults: existingResults
                ))
                return .none

            case .internal(.editScoreLoadFailed):
                // TODO: alert userowi. Na razie silent fail.
                return .none

                // MARK: - View Actions
                
            case .view(.viewDidAppear):
                guard !state.hasAppeared else { return .none }
                state.hasAppeared = true

                // The route child is NOT started here — `classRecap(.delegate(.didLoad))`
                // decides: class workouts never have a GPS route (mutual exclusion), so
                // the query and the "Trasa" spinner are skipped for them entirely.
                state.pendingRecapMapLoads = [.location, .metrics, .recap, .zones]
                return .merge(
                    .send(.heartRateZones(.load)),
                    .send(.performanceMetrics(.load)),
                    .send(.classRecap(.load)),
                    .send(.planScore(.fetchScore))
                )

            case .view(.linkTemplateTapped):
                state.destination = .linkTemplate(TemplatePickerFeature.State())
                return .none

            case .view(.editExistingScoreTapped):
                // Wyciągamy score ze state'a planScore (już załadowany z DB). Bez score'a guard
                // returnuje — button i tak jest schowany w UI gdy loadState != .loaded.
                guard case let .loaded(score) = state.planScore.loadState else { return .none }
                let workout = state.workout
                let trainingSessionId = score.trainingSessionId
                let existingResults = score.results
                return .run { [healthStore, trainingSessionClient] send in
                    do {
                        // Najpierw fetch templates — guard'ujemy że template istnieje przed
                        // expensive HK query. Edge case: user usunął template po treningu.
                        let templates = try await trainingSessionClient.fetchAll()
                        guard let trainingSession = templates.first(where: { $0.id == trainingSessionId }) else {
                            await send(.internal(.editScoreLoadFailed))
                            return
                        }
                        let (summary, hrBuffer) = try await WorkoutSummaryLoader.loadComplete(
                            for: workout,
                            healthStore: healthStore
                        )
                        await send(.internal(.editScoreLoaded(
                            summary: summary,
                            trainingSession: trainingSession,
                            hrBuffer: hrBuffer,
                            existingResults: existingResults
                        )))
                    } catch {
                        await send(.internal(.editScoreLoadFailed))
                    }
                }

                // MARK: - Destination

                // Manual-entry: TemplatePicker emit'uje wybrany template → ładujemy WorkoutSummary
                // + hrBuffer z HealthKit dla istniejącego HKWorkout, potem push SummaryFeature
                // w manual-init mode (skip checkSummary, pre-filled state).
            case let .destination(.presented(.linkTemplate(.delegate(.didSelectTemplate(template))))):
                let workout = state.workout
                return .run { [healthStore] send in
                    do {
                        let (summary, hrBuffer) = try await WorkoutSummaryLoader.loadComplete(
                            for: workout,
                            healthStore: healthStore
                        )
                        await send(.internal(.manualSummaryLoaded(
                            summary: summary,
                            trainingSession: template,
                            hrBuffer: hrBuffer
                        )))
                    } catch {
                        await send(.internal(.manualSummaryLoadFailed))
                    }
                }

            case .destination(.dismiss):
                // Manual-entry sheet (SummaryFeature) zamknięty — jeśli user zapisał
                // wyniki, sekcja Score musi je pokazać od razu, bez ponownego wejścia
                // w ekran. Refetch jest tani (fetchOne po hkWorkoutId).
                guard case .summary = state.destination else { return .none }
                return .send(.planScore(.fetchScore))

            case .destination:
                return .none

                // MARK: - Children

                // HR-zones child finished all three of its loads — check it off the
                // recap-map gate.
            case .heartRateZones(.delegate(.didFinishLoading)):
                state.pendingRecapMapLoads.remove(.zones)
                return recapMapEffectIfSettled(&state)

            case .heartRateZones:
                return .none

                // Metric card tapped in the child — navigation stays with the
                // parent because it owns the destinations.
            case let .performanceMetrics(.delegate(.openMetricDetails(metric))):
                state.destination = .metricDetail(MetricDetailFeature.State(metricType: metric))
                return .none

            case .performanceMetrics(.delegate(.didFinishLoading)):
                state.pendingRecapMapLoads.remove(.metrics)
                return recapMapEffectIfSettled(&state)

            case .performanceMetrics:
                return .none

            case .workoutRoute(.delegate(.didFinishLoading)):
                state.pendingRecapMapLoads.remove(.location)
                return recapMapEffectIfSettled(&state)

            case .workoutRoute:
                return .none

                // Recap fetch settled — this is where the recap↔route mutual
                // exclusion lives: a class workout never has a GPS route, so the
                // route load fires only when there is NO recap.
            case let .classRecap(.delegate(.didLoad(hasRecap))):
                state.pendingRecapMapLoads.remove(.recap)
                guard hasRecap else {
                    return .send(.workoutRoute(.load))
                }
                state.pendingRecapMapLoads.remove(.location)
                return recapMapEffectIfSettled(&state)

            case .classRecap:
                return .none

                // MARK: - Plan Score

                // Pending-results container tapped in the child — reuse the existing
                // edit flow (its `.loaded(score)` guard handles empty results too,
                // opening manual entry with `existingResults: []`).
            case .planScore(.delegate(.fillResultsTapped)):
                return .send(.view(.editExistingScoreTapped))

            case .planScore:
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)

        Scope(state: \.heartRateZones, action: \.heartRateZones) {
            HeartRateZonesFeature()
        }

        Scope(state: \.performanceMetrics, action: \.performanceMetrics) {
            PerformanceMetricsFeature()
        }

        Scope(state: \.workoutRoute, action: \.workoutRoute) {
            WorkoutRouteFeature()
        }

        Scope(state: \.classRecap, action: \.classRecap) {
            ClassRecapFeature()
        }

        Scope(state: \.planScore, action: \.planScore) {
            ActivityPlanScoreFeature()
        }
    }

    // MARK: - Recap map mounting

    /// Mounts the recap map only once every layout-affecting load has finished and the
    /// workout has class coordinates. The short sleep puts one settled frame between the
    /// last data pop-in and the map mount, so MapKit never initializes its Metal drawable
    /// mid-layout-churn (`CAMetalLayer width=0` render hang).
    private func recapMapEffectIfSettled(_ state: inout State) -> Effect<Action> {
        guard state.pendingRecapMapLoads.isEmpty,
              state.classRecap.classMapState == .loading,
              state.classRecap.hasCoordinates
        else { return .none }

        return .run { [clock] send in
            try? await clock.sleep(for: .milliseconds(300))
            await send(.classRecap(.mountMap))
        }
    }
}
