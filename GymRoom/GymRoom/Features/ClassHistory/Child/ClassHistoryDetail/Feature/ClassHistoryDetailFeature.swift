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
/// hold `[AthleteSummary]` w State. View renderuje 4 sekcje: top stats, HR chart
/// (per athlete / combined toggle), bar chart calories, pie chart zones.
@Reducer
struct ClassHistoryDetailFeature {

    @Dependency(\.gymClassClient) var gymClassClient

    @ObservableState
    struct State: Equatable {

        /// Snapshot session metadata (z `ClassSessionRecord` przy push z History row).
        let sessionId: UUID
        let className: String
        let location: String
        let startedAt: Date
        let endedAt: Date?

        /// Decoded athletes z BLOB-ów — async fetch + decode w `viewDidAppear`.
        var athletes: [AthleteSummary] = []

        /// Toggle widoku HR chart — `combined` (default, multi-series) vs `perAthlete`
        /// (lista kart per peer, każda z indywidualnym mini chart'em).
        var chartViewMode: ChartViewMode = .combined
    }

    /// Tryby wyświetlania HR over time. Switch'owane przez `SegmentedPicker` w View.
    enum ChartViewMode: String, CaseIterable, Identifiable, Sendable, Equatable {

        /// Multi-series line chart — wszyscy athletes na jednej skali czasu, kolor per nick.
        /// Dobry do porównania "kto się wyróżniał" w klasie.
        case combined

        /// Lista kart, każda z mini chart'em jednego athlete'a. Dobry do indywidualnego
        /// debugging "jak Seba sobie radził w drugiej rundzie".
        case perAthlete

        var id: String { rawValue }

        var title: String {
            switch self {
            case .combined: String(localized: "Combined", bundle: .main)
            case .perAthlete: String(localized: "Per athlete", bundle: .main)
            }
        }
    }

    @CasePathable
    enum Action: ViewAction, BindableAction {

        /// Bindings dla Picker'a chartViewMode (SegmentedControl).
        case binding(BindingAction<State>)

        /// Internal — result async fetch + decode.
        case athletesLoaded([AthleteSummary])

        case view(View)

        enum View {
            /// Lifecycle — fetch athletes na pojawienie się detail. `.task` w View.
            case viewDidAppear
        }
    }

    var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce<State, Action> { state, action in
            switch action {

            case .view(.viewDidAppear):
                let sessionId = state.sessionId
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
                            samples: samples,
                            analytics: analytics
                        )
                    }
                    await send(.athletesLoaded(summaries))
                } catch: { error, _ in
                    Logger.gymRoom.error("❌ fetchAthletesForSession failed: \(error.localizedDescription)")
                }

            case let .athletesLoaded(summaries):
                state.athletes = summaries
                return .none

            case .binding:
                return .none
            }
        }
    }
}
