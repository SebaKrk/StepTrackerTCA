//
//  ExerciseDetailFeature.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 24/04/2026.
//

import ComposableArchitecture
import Commons
import Foundation
import HealthHub
import SharedModels
import UIKit

@Reducer
struct ExerciseDetailFeature {

    // MARK: - Dependency

    @Dependency(\.exerciseLogClient) var exerciseLogClient
    @Dependency(\.workoutPlanScoreClient) var workoutPlanScoreClient
    @Dependency(\.activityClient) var activityClient
    @Dependency(\.maxHeartRateClient) var maxHeartRateClient
    @Dependency(\.calendar) var calendar
    @Dependency(\.dismiss) var dismiss

    // MARK: - Reducer

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {

            case .view(.onAppear):
                let exerciseType = state.exerciseType
                return .run { [exerciseLogClient] send in
                    let logs = try await exerciseLogClient.fetchByExerciseType(exerciseType)
                    await send(.logsLoaded(logs))
                }

            case let .logsLoaded(logs):
                state.logs = logs
                state.weeklyVolume = computeWeeklyVolume(from: logs)
                return .none

            case let .view(.historyRowTapped(scoreId)):
                guard !state.isLoadingActivity else { return .none }
                state.isLoadingActivity = true
                return .run { [workoutPlanScoreClient, activityClient, maxHeartRateClient] send in
                    do {
                        guard let score = try await workoutPlanScoreClient.fetchById(scoreId),
                              let workout = try await activityClient.fetchWorkoutById(score.hkWorkoutId)
                        else {
                            await send(.activityLoadFailed)
                            return
                        }
                        let maxHR = await maxHeartRateClient.forWorkout(workout)
                        await send(.activityLoaded(workout, maxHR))
                    } catch {
                        await send(.activityLoadFailed)
                    }
                }
                .cancellable(id: ExerciseDetailFeatureCancelID.activityFetch, cancelInFlight: true)

            case let .activityLoaded(workout, maxHR):
                state.isLoadingActivity = false
                state.activityDetail = ActivityDetailsFeature.State(workout: workout, maxHeartRate: maxHR)
                return .none

            case .activityLoadFailed:
                // TODO: Surface a user-visible alert (e.g., "Trening niedostępny — mógł zostać
                // usunięty z aplikacji Zdrowie") + `reportIssue(...)` for telemetry.
                // Today this fails silently: loader flag clears, push doesn't happen,
                // user sees nothing. Pattern reference: `PersonalActivityFeature.errorAlert`.
                state.isLoadingActivity = false
                return .none

            case .activityDetail:
                return .none

            case .view(.copyUnmatchedNamesTapped):
                // DEBUG-only diagnostics (the card sending this is #if DEBUG):
                // plain-text "name<TAB>count" lines, ready to paste into a chat
                // or spreadsheet when extending the ExerciseType catalog.
                let list = state.unmatchedNameCounts
                    .map { "\($0.name)\t\($0.count)" }
                    .joined(separator: "\n")
                return .run { _ in
                    await MainActor.run { UIPasteboard.general.string = list }
                }

            case .view(.dismissTapped):
                return .run { _ in await self.dismiss() }

            case .view(.sendToDeveloperTapped):
                state.alert = .confirmSendReport
                return .none

            case .alert(.presented(.sendReportConfirmed)):
                let text = state.unrecognizedNamesReport
                return .run { send in
                    let url = FileManager.default.temporaryDirectory
                        .appendingPathComponent("unrecognized-exercises.txt")
                    guard (try? Data(text.utf8).write(to: url, options: .atomic)) != nil else { return }
                    await send(.reportFileReady(url))
                }

            case .alert:
                return .none

            case let .reportFileReady(url):
                state.reportShareFile = .init(url: url)
                return .none

            case .view(.shareSheetDismissed):
                state.reportShareFile = nil
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
        .ifLet(\.$activityDetail, action: \.activityDetail) {
            ActivityDetailsFeature()
        }
    }

    // MARK: - Private

    private func computeWeeklyVolume(from logs: [ExerciseLog]) -> [State.WeeklyVolumePoint] {
        let grouped = Dictionary(grouping: logs) { log in
            calendar.startOfWeek(for: log.date)
        }
        return grouped.map { weekStart, weekLogs in
            let volume = weekLogs.reduce(0.0) { total, log in
                // Weighted: use volumeLoad (reps × weight)
                if let vl = log.volumeLoad, vl > 0 { return total + vl }
                // Bodyweight: sum reps as volume
                guard let repsStr = log.actualReps else { return total }
                let reps = repsStr.split(separator: "-")
                    .compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
                    .reduce(0, +)
                return total + Double(reps)
            }
            return State.WeeklyVolumePoint(week: weekStart, volume: volume)
        }
        .sorted { $0.week < $1.week }
    }
}

// MARK: - Alert State

extension AlertState where Action == ExerciseDetailFeature.Action.Alert {

    /// Consent gate for the unrecognized-names report — says exactly what leaves
    /// the device before the share sheet appears.
    static let confirmSendReport = AlertState {
        TextState("Send to the developer?")
    } actions: {
        ButtonState(role: .cancel) {
            TextState("Cancel")
        }
        ButtonState(action: .sendReportConfirmed) {
            TextState("Send")
        }
    } message: {
        TextState("You'll share a .txt file with the unrecognized exercise names and their occurrence counts — no workout data included.")
    }
}

