//
//  DefaultTrainingReadinessCalculator.swift
//  HealthHub
//
//  Created by Sebastian Sciuba on 28/09/2025.
//

import ComposableArchitecture
import Foundation
import SharedModels

/// Default readiness calculator.
///
/// A value type: it holds only injected dependencies and no mutable state, so it
/// is `Sendable` on its own terms rather than by an `@unchecked` promise.
public struct DefaultTrainingReadinessCalculator: TrainingReadinessCalculator {

    // MARK: - Dependency

    @Dependency(\.personalDataManager) var personalDataManager
    @Dependency(\.sleepDataManager) var sleepDataManager
    @Dependency(\.readinessHistoryClient) var readinessHistoryClient
    @Dependency(\.date) var date
    @Dependency(\.calendar) var calendar

    // MARK: - Properties

    /// How many days with data a baseline needs.
    let baselineDayCount = 7

    /// How far back to look for those days.
    ///
    /// A gap no longer shrinks the baseline, it only reaches further back — the
    /// same shape Apple uses for overnight vitals (7 nights out of 49).
    let baselinePoolDays = 49

    /// Resolves which day is being scored, and whether it can be scored yet.
    ///
    /// Built per call so its own dependencies resolve in the caller's context.
    private var dayResolver: ReadinessDayResolver {
        ReadinessDayResolver()
    }

    /// Resolves what a night's recording says, before anything scores it.
    ///
    /// Built per call for the same reason as `dayResolver`.
    var nightMeasurementResolver: NightMeasurementResolver {
        NightMeasurementResolver()
    }

    /// How many nights the long-term sleep average covers.
    ///
    /// Long enough that a habit shows and a bad week does not. Unrelated to the
    /// baseline pool: that one asks what is normal for the user, this one asks
    /// whether that normal is enough.
    let longTermSleepNightCount = 60

    /// How many days of history a rebuild reaches back over.
    ///
    /// Two months is enough for the trend chart to mean something from the first
    /// launch, without turning the rebuild into a long job.
    let backfillDayCount = 60

    // MARK: - Lifecycle

    public init() {}

    // MARK: - API

    public func calculateReadinessOutcome() async throws -> ReadinessOutcome {
        let resolver = dayResolver

        guard let day = try await resolver.resolve() else {
            return .awaitingSleepData(expectedBy: resolver.expectedAvailability())
        }

        let result = try await calculateTrainingReadiness(for: day)

        if result.healthKitAccessDenied {
            return .accessDenied
        }

        if result.hasInsufficientData {
            return .insufficientData
        }

        // Persisted here rather than in the feature, so the background observer
        // path records history too — it is what runs on most mornings. Only days
        // worth showing are stored; a partial read must not enter the trend.
        // A failed write must not cost the user today's score.
        do {
            try await readinessHistoryClient.save(result, day)
        } catch {
            #if DEBUG
            print("❌ Failed to persist readiness for \(day.dayStart): \(error.localizedDescription)")
            #endif
        }

        return .ready(result)
    }

    /// Calculates readiness for an already resolved day.
    ///
    /// Separated so the day can be resolved once and reused — and so the scoring
    /// itself takes no reading of the current time.
    ///
    /// - Parameter day: The day to score
    /// - Returns: The readiness result for that day
    /// - Throws: HealthKit errors if data access fails
    func calculateTrainingReadiness(for day: ReadinessDay) async throws -> TrainingReadinessResult {
        // HRV and sleep compare against the same nights, and running them in
        // parallel meant each fetched that set for itself — 49 nights read twice
        // every morning, and 120 identical reads in a 60-day rebuild. Resolved
        // once, before the fan-out, at the cost of one serialised read.
        let nightWindows = try await baselineNightWindows(for: day)

        // The four components share no state and each issues its own HealthKit
        // reads, so running them in sequence only added up their latencies.
        async let restingHeartRateComponent = calculateRestingHeartRateScore(for: day)
        async let hrvComponent = calculateHRVScore(for: day, baselineWindows: nightWindows)
        async let sleepComponent = calculateSleepScore(for: day, baselineWindows: nightWindows)
        async let activityLoadComponent = calculateActivityLoadScore(for: day)

        let components = try await TrainingReadinessComponents(
            restingHeartRate: restingHeartRateComponent,
            heartRateVariability: hrvComponent,
            sleepQuality: sleepComponent,
            previousDayLoad: activityLoadComponent
        )

        let overallScore = calculateOverallScore(from: components)
        let isReliable = checkReliability(components: components)

        return TrainingReadinessResult(
            overallScore: overallScore,
            components: components,
            calculatedAt: date.now,
            isReliable: isReliable
        )
    }

    public func getTrainingReadinessHistory(days: Int) async throws -> [TrainingReadinessResult] {
        try await readinessHistoryClient.history(days)
    }

    /// Baseline windows shaped like the night the day was measured over.
    ///
    /// A sleep-anchored day reads HRV and sleep from the session itself, so its
    /// baseline has to be sessions too. Comparing roughly seven asleep hours
    /// against fourteen-hour clock windows that also cover the evening and the
    /// morning awake biased every comparison the same way — HRV is lower awake,
    /// so the difference read as a surplus that was not there, and that surplus
    /// is what pushes a day across a level boundary.
    ///
    /// A clock-anchored day has no session to measure, so both sides stay
    /// clock-shaped and the comparison is consistent again.
    ///
    /// - Parameter day: The readiness day being calculated
    /// - Returns: Baseline windows, newest first
    /// - Throws: HealthKit errors if sleep data cannot be read
    func baselineNightWindows(for day: ReadinessDay) async throws -> [ClosedRange<Date>] {
        let pool = TrainingReadinessTimeWindows.previousNights(
            count: baselinePoolDays,
            before: day,
            calendar: calendar
        )

        guard day.sleepSession != nil else { return pool }

        guard let searchStart = pool.map(\.lowerBound).min(),
              let searchEnd = pool.map(\.upperBound).max() else {
            return []
        }

        let sessions = try await sleepDataManager.nightSessions(
            in: searchStart...searchEnd,
            calendar: calendar
        )

        // Mapped over the pool rather than over the dictionary, so the result keeps
        // the pool's newest-first order that `takingFirst` depends on.
        return pool.compactMap { night in
            sessions[calendar.startOfDay(for: night.upperBound)]
                .map { $0.start...$0.end }
        }
    }

    public func rebuildHistoryIfNeeded() async throws -> Int {
        // The version flag lives outside the database, so a migration that clears
        // the table can leave the flag claiming a rebuild that no longer exists.
        // An empty history is therefore its own reason to rebuild.
        let isRebuilt = readinessHistoryClient.backfilledVersion() >= ReadinessAlgorithm.currentVersion
        let hasHistory = try await !readinessHistoryClient.history(backfillDayCount).isEmpty

        guard !isRebuilt || !hasHistory else { return 0 }

        let count = try await rebuildHistory(days: backfillDayCount)

        // Marked even when nothing was written: with no history in HealthKit there
        // is nothing to catch up on, and retrying every launch would never end.
        // Days recorded from now on arrive through the normal path anyway.
        readinessHistoryClient.setBackfilledVersion(ReadinessAlgorithm.currentVersion)

        return count
    }

    // MARK: - Private Methods

    /// Scores every day in the window and writes them in one batch.
    ///
    /// - Parameter days: How many days back to rebuild
    /// - Returns: How many days had enough data to store
    private func rebuildHistory(days: Int) async throws -> Int {
        let resolver = dayResolver
        let today = calendar.startOfDay(for: date.now)

        var scored: [ReadinessDayResult] = []

        // Sequential on purpose: each day issues a handful of HealthKit reads, and
        // a task group spanning two months floods the daemon without buying time.
        for dayOffset in 1...max(days, 1) {
            try Task.checkCancellation()

            guard let dayStart = calendar.date(byAdding: .day, value: -dayOffset, to: today),
                  let day = try await resolver.resolve(forDayStartingAt: dayStart) else {
                continue
            }

            let result = try await calculateTrainingReadiness(for: day)

            // Same bar as a live calculation: a partial day must not enter the
            // trend. A completely empty day is skipped like any other — it is far
            // more likely to predate the user's Watch than to mean a refusal, and
            // `healthKitAccessDenied` (four missing components) cannot tell those
            // apart. Aborting on it discarded every day already scored.
            guard !result.hasInsufficientData else { continue }

            scored.append(ReadinessDayResult(result: result, day: day))
        }

        guard !scored.isEmpty else { return 0 }

        try await readinessHistoryClient.saveMany(scored)

        return scored.count
    }

    /// Combines component scores into a 0-100 readiness score.
    ///
    /// Normalises against the components that are actually present, so a day
    /// missing HRV is not scored lower than the same day with it. A day where
    /// every component sits on its own baseline lands on the neutral score.
    private func calculateOverallScore(from components: TrainingReadinessComponents) -> Int {
        let available = components.available

        guard !available.isEmpty else { return ReadinessLevel.neutralScore }

        let points = available.reduce(0) { $0 + $1.score }

        // Positive and negative headroom differ per component, so the direction
        // of the deviation decides which pool it is measured against.
        let headroom = points >= 0
            ? available.reduce(0) { $0 + $1.maxScore }
            : available.reduce(0) { $0 + abs($1.minScore) }

        guard headroom > 0 else { return ReadinessLevel.neutralScore }

        let span = Double(ReadinessLevel.neutralScore)
        let offset = (span * Double(points) / Double(headroom)).rounded()

        return max(0, min(100, ReadinessLevel.neutralScore + Int(offset)))
    }

    private func checkReliability(components: TrainingReadinessComponents) -> Bool {
        components.available.count >= TrainingReadinessResult.minimumReliableComponents
    }
}
