//
//  NightMeasurementResolver.swift
//  HealthHub
//
//  Created by Sebastian Ściuba on 09/11/2026.
//

import ComposableArchitecture
import Foundation
import SharedModels

/// Decides what a night's recording says before anything scores it.
///
/// Sits beside `ReadinessDayResolver`, which answers "which day", and
/// `SleepSessionBuilder`, which answers "which session". This one answers "what
/// happened" — a question that needs heart rate as well as sleep, and therefore
/// does not belong in a component calculator whose job is arithmetic on hours.
struct NightMeasurementResolver {

    // MARK: - Dependency

    @Dependency(\.sleepDataManager) var sleepDataManager
    @Dependency(\.personalDataManager) var personalDataManager

    // MARK: - Properties

    /// How long heart rate must cover the night to prove the Watch was worn.
    private let minimumNightCoverage: TimeInterval = 4 * 60 * 60

    /// How close to a session's end heart rate must stop to look truncated.
    private let truncationGrace: TimeInterval = 30 * 60

    /// How much unmeasured night must follow for truncation to be the likely cause.
    private let minimumTruncationGap: TimeInterval = 2 * 60 * 60

    // MARK: - API

    /// Resolves what the night's recording says.
    ///
    /// - Parameter day: The readiness day being calculated
    /// - Returns: The measurement, or why there is none
    /// - Throws: HealthKit errors if data access fails
    func resolve(for day: ReadinessDay) async throws -> NightMeasurement {
        if let session = day.sleepSession, session.asleepHours > 0 {
            if try await isTruncated(session: session, within: day) {
                return .truncated
            }

            return .measured(hours: session.asleepHours)
        }

        if let measured = try await sleepDataManager.getAverageSleepHours(
            in: [day.nightWindow],
            takingFirst: 1
        ), measured.value > 0 {
            return .measured(hours: measured.value)
        }

        return try await wasWornThroughout(day) ? .noSleep : .notWorn
    }

    // MARK: - Private Methods

    /// Whether heart rate covers enough of the night to prove the Watch was worn.
    private func wasWornThroughout(_ day: ReadinessDay) async throws -> Bool {
        guard let coverage = try await personalDataManager.heartRateCoverage(
            in: day.nightWindow
        ) else {
            return false
        }

        return coverage.covered >= minimumNightCoverage
    }

    /// Whether the recording appears to have stopped rather than the night ended.
    ///
    /// Two things have to hold together: heart rate stops when the session does,
    /// and a meaningful stretch of night follows with nothing in it. On a normal
    /// morning heart rate also stops at the session's end, but there is no night
    /// left after it — which is what tells the two apart.
    private func isTruncated(
        session: SleepSession,
        within day: ReadinessDay
    ) async throws -> Bool {
        guard let coverage = try await personalDataManager.heartRateCoverage(
            in: day.nightWindow
        ) else {
            return false
        }

        let stoppedWithSession = abs(
            coverage.lastSample.timeIntervalSince(session.end)
        ) <= truncationGrace

        let unmeasuredAfter = day.nightWindow.upperBound.timeIntervalSince(session.end)

        return stoppedWithSession && unmeasuredAfter >= minimumTruncationGap
    }
}
