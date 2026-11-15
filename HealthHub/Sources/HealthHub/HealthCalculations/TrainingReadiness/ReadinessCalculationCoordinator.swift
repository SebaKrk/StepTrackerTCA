//
//  ReadinessCalculationCoordinator.swift
//  HealthHub
//
//  Created by Sebastian Ściuba on 15/11/2026.
//

import Foundation
import SharedModels

/// Serves one readiness calculation to everyone who asks for it.
///
/// The readiness card and the metric tiles each ask on their own appearance, at
/// the same moment, and one run reads four components against a 49-day baseline
/// pool. Without this the stats screen did all of that twice.
public actor ReadinessCalculationCoordinator {

    // MARK: - Properties

    /// How long a finished calculation keeps answering.
    ///
    /// Short enough that a new day, or a night that closed while the app was
    /// open, is picked up on the next visit; long enough to cover leaving the
    /// tab and coming back.
    private static let lifetime: Duration = .seconds(300)

    /// Produces a fresh outcome. Injected so the actor holds no dependencies.
    private let calculate: @Sendable () async throws -> ReadinessOutcome

    /// The last outcome and when it was produced.
    ///
    /// Timed on the continuous clock rather than on `Date`: this is an age, and
    /// an age measured against the wall clock changes when the wall clock does.
    private var cache: (outcome: ReadinessOutcome, at: ContinuousClock.Instant)?

    /// The calculation currently running, shared with everyone who asks meanwhile.
    private var inFlight: Task<ReadinessOutcome, any Error>?

    // MARK: - Lifecycle

    /// Creates a coordinator over one calculation.
    ///
    /// - Parameter calculate: Runs a full readiness calculation
    public init(calculate: @escaping @Sendable () async throws -> ReadinessOutcome) {
        self.calculate = calculate
    }

    // MARK: - API

    /// The outcome for now: cached, already running, or freshly calculated.
    ///
    /// - Returns: The readiness outcome
    /// - Throws: Whatever the calculation throws
    public func outcome() async throws -> ReadinessOutcome {
        if let cache, cache.at.duration(to: .now) < Self.lifetime {
            return cache.outcome
        }

        return try await run()
    }

    /// Drops the cached outcome, so the next ask calculates again.
    ///
    /// Called when the user asks for a refresh: a pull that returns the same
    /// number it was given five minutes ago reads as a broken gesture.
    public func invalidate() {
        cache = nil
    }

    // MARK: - Private Methods

    /// Runs the calculation, or joins the one already running.
    private func run() async throws -> ReadinessOutcome {
        if let inFlight {
            return try await inFlight.value
        }

        // Unstructured on purpose: one caller walking away — a cancelled effect,
        // a dismissed screen — must not take the calculation from the other.
        let task = Task { [calculate] in
            try await calculate()
        }
        inFlight = task

        defer { inFlight = nil }

        let outcome = try await task.value
        cache = (outcome, .now)

        return outcome
    }
}
