//
//  ClassHistoryDetailFeature.swift
//  GymRoom
//
//  Created by Sebastian Ściuba on 18/06/2026.
//

import AppDatabase
import ComposableArchitecture
import Foundation
import OSLog
import SharedModels

/// Reducer dla detail view klasy z History tab. Fetch athletes async, decode BLOB-y,
/// pre-aggregate range bars per athlete (off main), hold w State. View renderuje:
/// top stats banner, HR chart toggle (combined LineMark / perAthlete BarMark range
/// z selection), calories bar chart.
@Reducer
struct ClassHistoryDetailFeature {

    @Dependency(\.gymClassClient) var gymClassClient

    var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce<State, Action> { state, action in
            switch action {

            case .view(.viewDidAppear):
                let sessionId = state.sessionId
                state.viewState = .loading
                return .run { send in
                    let records = try await gymClassClient.fetchAthletesForSession(sessionId)
                    let decoder = JSONDecoder()
                    let summaries: [AthleteSummary] = records.compactMap { record in
                        guard
                            let samples = try? decoder.decode([HRSample].self, from: record.hrSamplesData),
                            let analytics = try? decoder.decode(ClassAnalytics.self, from: record.aggregatedStatsData)
                        else {
                            Logger.gymRoom.error("❌ Failed to decode BLOB for athlete \(record.id)")
                            return nil
                        }
                        return AthleteSummary(
                            id: record.id,
                            deviceID: record.deviceID,
                            nick: record.nick,
                            maxHR: record.maxHR,
                            joinedAt: record.joinedAt,
                            leftAt: record.leftAt,
                            // Zero-bpm samples are disconnect artifacts, not measurements —
                            // they dragged chart lines down to 0 (both the combined
                            // LineMark and the per-athlete range bars).
                            samples: samples.filter { $0.bpm > 0 },
                            analytics: analytics
                        )
                    }
                    let ranges = Dictionary(
                        uniqueKeysWithValues: summaries.map { athlete in
                            (athlete.id, HRSample.minuteRanges(from: athlete.samples))
                        }
                    )
                    // Gap-aware segments for the combined chart — precomputed here
                    // (same pattern as `ranges`) so scrubbing never re-runs the O(n) split.
                    let segments = Dictionary(
                        uniqueKeysWithValues: summaries.map { athlete in
                            (athlete.id, AthleteSummary.hrSegments(from: athlete.samples))
                        }
                    )
                    await send(.athletesLoaded(summaries, ranges, segments))
                } catch: { error, send in
                    Logger.gymRoom.error("❌ fetchAthletesForSession failed: \(error.localizedDescription)")
                    await send(.fetchFailed)
                }

            case let .athletesLoaded(summaries, ranges, segments):
                state.athletes = summaries
                state.hrRangesByAthlete = ranges
                state.hrSegmentsByAthlete = segments
                // Outage bands are a cheap derivation of the segment boundaries —
                // O(segments), no need to widen the action signature.
                state.hrGapsByAthlete = segments.mapValues(AthleteSummary.measurementGaps(from:))
                // Ranking table ("Points" tab, IPAD-00095-B) — built from the same
                // decoded analytics; identical rows as the end-of-class cover.
                state.results = ClassResultsFeature.State(
                    className: state.className,
                    rows: ClassResultsFeature.rows(from: summaries)
                )
                state.viewState = .success
                return .none

            case .fetchFailed:
                state.viewState = .failed
                return .none

            case let .minuteSelected(athleteID, date):
                if let date {
                    state.selectedMinutes[athleteID] = date
                } else {
                    state.selectedMinutes.removeValue(forKey: athleteID)
                }
                return .none

            case let .combinedTimeSelected(date):
                state.selectedCombinedTime = date
                return .none

            case .view(.deleteTapped):
                state.alert = .deleteSession(state.className)
                return .none

            case .alert(.presented(.confirmDelete)):
                let sessionId = state.sessionId
                return .run { send in
                    try? await gymClassClient.deleteSession(sessionId)
                    await send(.delegate(.sessionDeleted(sessionId)))
                }

            case .alert, .delegate, .binding, .results:
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)

        Scope(state: \.results, action: \.results) {
            ClassResultsFeature()
        }
    }
}
