//
//  HeartRateZonesFeature.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 16/07/2026.
//

import ComposableArchitecture
import Foundation
import HealthHub
import HealthKit
import SharedModels

/// HR-zones domain of the Activity Details screen: time-in-zone distribution,
/// frozen effort points and the per-minute HR range chart.
///
/// Runs three independent loads (zones, effort score, minute ranges) and emits
/// `delegate(.didFinishLoading)` once ALL of them settle — the parent counts
/// that signal into its recap-map gate.
@Reducer
struct HeartRateZonesFeature {

    // MARK: - Dependency

    @Dependency(\.activityClient) var activityClient
    @Dependency(\.effortScoreClient) var effortScoreClient
    @Dependency(\.healthStore) var healthStore

    // MARK: - State

    @ObservableState
    struct State {

        /// The workout being displayed.
        var workout: HKWorkout

        /// User's maximum heart rate for zone calculations.
        var maxHeartRate: Double

        /// Primary heart rate zone info (dominant zone and duration).
        var primaryZoneInfo: PrimaryZoneInfo?

        /// Time spent in each heart rate zone. `nil` until loaded (and on load
        /// failure) — the zones section stays hidden then.
        var zoneDistribution: [HeartRateZone: TimeInterval]?

        /// Whether the zone distribution section is expanded.
        var isExpandZone = false

        /// Zones section toggle: `false` shows time per zone, `true` shows the
        /// points each zone contributed. Flipped by tapping the expanded rows.
        var showZonePoints = false

        /// Frozen effort score (Myzone-style) read from the DB. Whole record — the
        /// zone rows break points down from the FROZEN `secondsByZone` (same source
        /// as the total), so the breakdown always sums to the badge. `nil` = not
        /// computed (pre-feature workout / no HR) → badge hidden.
        var effortScore: WorkoutEffortScore?

        /// Per-minute HR aggregation (min/max BPM) feeding the range bar chart.
        var hrMinuteRanges: [HRMinuteRange] = []

        /// Selected minute on the HR chart (`chartXSelection`). `nil` = no selection.
        var selectedMinute: Date?

        /// Loads still in flight — `didFinishLoading` fires when this empties.
        var pendingLoads: Set<PendingLoad> = []

        enum PendingLoad: Hashable {
            case effortScore
            case hrMinuteRanges
            case zoneDistribution
        }

        /// Total time across all heart rate zones.
        var totalZoneDuration: TimeInterval {
            zoneDistribution?.values.reduce(0, +) ?? 0
        }
    }

    // MARK: - Action

    @CasePathable
    enum Action: ViewAction {

        /// Command from the parent — starts all three loads.
        case load

        case `internal`(Internal)

        enum Internal {

            /// `nil` = load failed; the section stays hidden either way.
            case zoneDistributionLoaded([HeartRateZone: TimeInterval]?)

            /// `nil` for workouts recorded before the effort-points feature shipped.
            case effortScoreLoaded(WorkoutEffortScore?)

            /// Empty = no HR samples (chart hidden).
            case hrMinuteRangesLoaded([HRMinuteRange])
        }

        case view(View)

        enum View {

            /// Disclosure chevron toggled on the zones section.
            case zoneDisclosureToggled(Bool)

            /// Expanded rows tapped — flips time ↔ points display.
            case zonePointsToggled

            /// Chart scrubbed — selected minute (`nil` on deselect).
            case minuteSelected(Date?)
        }

        case delegate(Delegate)

        @CasePathable
        enum Delegate {

            /// All three loads settled (successfully or not).
            case didFinishLoading
        }
    }

    // MARK: - Reducer

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {

            case .load:
                state.pendingLoads = [.effortScore, .hrMinuteRanges, .zoneDistribution]
                return .merge(
                    loadZoneDistribution(state),
                    loadEffortScore(state),
                    loadHRMinuteRanges(state)
                )

            case let .internal(.zoneDistributionLoaded(distribution)):
                state.zoneDistribution = distribution
                state.pendingLoads.remove(.zoneDistribution)
                return finishIfSettled(state)

            case let .internal(.effortScoreLoaded(score)):
                state.effortScore = score
                state.pendingLoads.remove(.effortScore)
                return finishIfSettled(state)

            case let .internal(.hrMinuteRangesLoaded(ranges)):
                state.hrMinuteRanges = ranges
                state.pendingLoads.remove(.hrMinuteRanges)
                return finishIfSettled(state)

            case let .view(.zoneDisclosureToggled(isExpanded)):
                state.isExpandZone = isExpanded
                return .none

            case .view(.zonePointsToggled):
                state.showZonePoints.toggle()
                return .none

            case let .view(.minuteSelected(date)):
                state.selectedMinute = date
                return .none

            case .delegate:
                return .none
            }
        }
    }

    // MARK: - Load effects

    private func loadZoneDistribution(_ state: State) -> Effect<Action> {
        .run { [activityClient, workout = state.workout, maxHeartRate = state.maxHeartRate] send in
            // `try?` → `nil` on failure keeps the section hidden AND still counts
            // the load as settled, so `didFinishLoading` always reaches the parent.
            let distribution = try? await activityClient.fetchZoneDistribution(workout, maxHeartRate)
            await send(.internal(.zoneDistributionLoaded(distribution)))
        }
    }

    private func loadEffortScore(_ state: State) -> Effect<Action> {
        .run { [effortScoreClient, id = state.workout.uuid] send in
            let score = try? await effortScoreClient.fetchByHKWorkoutId(id)
            await send(.internal(.effortScoreLoaded(score)))
        }
    }

    private func loadHRMinuteRanges(_ state: State) -> Effect<Action> {
        .run { [healthStore, workout = state.workout] send in
            do {
                let samples = try await WorkoutSummaryLoader.heartRateSamples(
                    for: workout,
                    healthStore: healthStore
                )
                // Tuple → HRSample (activeEnergy is unused by the aggregation → 0).
                let hrSamples = samples.map {
                    HRSample(timestamp: $0.date, bpm: Int($0.bpm.rounded()), activeEnergy: 0)
                }
                let ranges = HRSample.minuteRanges(from: hrSamples)
                await send(.internal(.hrMinuteRangesLoaded(ranges)))
            } catch {
                // Silent fail — no HR samples (e.g. indoor without Watch) = chart hidden.
                await send(.internal(.hrMinuteRangesLoaded([])))
            }
        }
    }

    /// Emits `didFinishLoading` when the last in-flight load settles.
    private func finishIfSettled(_ state: State) -> Effect<Action> {
        guard state.pendingLoads.isEmpty else { return .none }
        return .send(.delegate(.didFinishLoading))
    }
}
