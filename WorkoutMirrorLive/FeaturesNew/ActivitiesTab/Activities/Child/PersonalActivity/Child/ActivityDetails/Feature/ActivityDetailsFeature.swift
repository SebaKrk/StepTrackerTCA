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
import CoreLocation

@Reducer
struct ActivityDetailsFeature {

    // MARK: - Dependency

    @Dependency(\.activityClient) var activityClient
    @Dependency(\.healthStore) var healthStore
    @Dependency(\.trainingSessionClient) var trainingSessionClient
    
    // MARK: - Reducer
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
                
                // MARK: - Internal State Updates
                
            case let .internal(.zoneDistributionLoaded(distribution)):
                state.zoneDistribution = distribution
                return .none
                
            case let .internal(.metricsLoaded(mets, trimp, hrTSS, hrRecovery, intensityFactor, recoveryDemand)):
                state.mets = mets
                state.trimp = trimp
                state.hrTSS = hrTSS
                state.hrRecovery = hrRecovery
                state.intensityFactor = intensityFactor
                state.recoveryDemand = recoveryDemand
                return .none
                
            case let .internal(.zoneExpand(value)):
                state.isExpandZone = value
                return .none
                
            case let .internal(.locationDataLoaded(coordinates)):
                state.routeCoordinates = coordinates
                state.isLoadingLocation = false
                return .none
                
                // MARK: - Internal Data Loading
                
            case .internal(.loadZoneDistribution):
                let workout = state.workout
                let maxHeartRate = state.maxHeartRate
                
                return .run { send in
                    let distribution = try await activityClient.fetchZoneDistribution(workout, maxHeartRate)
                    await send(.internal(.zoneDistributionLoaded(distribution)))
                }
                
            case .internal(.loadMetrics):
                let workout = state.workout
                let maxHeartRate = state.maxHeartRate
                
                return .run { send in
                    async let metsTask = activityClient.fetchMETs(workout)
                    async let trimpTask = activityClient.fetchTRIMP(workout, maxHeartRate)
                    async let hrTSSTask = activityClient.fetchHRTSS(workout, maxHeartRate)
                    async let hrRecoveryTask = activityClient.fetchHRRecovery(workout)
                    async let intensityFactorTask = activityClient.fetchIntensityFactor(workout, maxHeartRate)
                    async let recoveryDemandTask = activityClient.fetchRecoveryDemand(workout, maxHeartRate)
                    
                    let mets = try? await metsTask
                    let trimp = try? await trimpTask
                    let hrTSS = try? await hrTSSTask
                    let hrRecovery = try? await hrRecoveryTask
                    let intensityFactor = try? await intensityFactorTask
                    let recoveryDemand = try? await recoveryDemandTask
                    
                    await send(.internal(.metricsLoaded(
                        mets: mets,
                        trimp: trimp,
                        hrTSS: hrTSS,
                        hrRecovery: hrRecovery,
                        intensityFactor: intensityFactor,
                        recoveryDemand: recoveryDemand
                    )))
                }
                
            case .internal(.loadLocationData):
                let workout = state.workout
                state.isLoadingLocation = true

                return .run { send in
                    do {
                        let locations = try await activityClient.fetchWorkoutRoute(workout)
                        let coordinates = locations.map { $0.coordinate }
                        await send(.internal(.locationDataLoaded(coordinates)))
                    } catch {
                        // W przypadku błędu zwracamy pustą tablicę (indoor workout)
                        await send(.internal(.locationDataLoaded([])))
                    }
                }

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
                guard state.zoneDistribution == nil else { return .none }

                return .merge(
                    .send(.internal(.loadZoneDistribution)),
                    .send(.internal(.loadMetrics)),
                    .send(.internal(.loadLocationData)),
                    .send(.planScore(.fetchScore))
                )
                
            case let .view(.zoneDiscusserButtonTapped(value)):
                return .send(.internal(.zoneExpand(value)))
                
            case let .view(.openMetricDetails(metric)):
                state.destination = .metricDetail(MetricDetailFeature.State(metricType: metric))
                return .none

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

            case .destination:
                return .none

                // MARK: - Plan Score

            case .planScore:
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)

        Scope(state: \.planScore, action: \.planScore) {
            ActivityPlanScoreFeature()
        }
    }
}
