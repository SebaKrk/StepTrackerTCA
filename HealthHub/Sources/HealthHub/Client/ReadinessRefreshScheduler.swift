//
//  ReadinessRefreshScheduler.swift
//  HealthHub
//
//  Created by Sebastian Ściuba on 13/11/2026.
//

// `BGTask` carries no Sendable annotations yet, and the launch handler hands it
// to us on one queue and expects `setTaskCompleted` back from the same work. The
// contract is single-threaded by design; only the annotations are missing.
@preconcurrency import BackgroundTasks
import ComposableArchitecture
import Foundation

/// Asks the system to wake the app so readiness can be recalculated.
///
/// The widget had one way of learning about a new score: a HealthKit observer
/// waking the app. That wake is at the system's discretion and is withheld on a
/// low battery, which is exactly when a morning score goes stale. This is the
/// second, independent way of asking.
///
/// Neither is a guarantee — `earliestBeginDate` is a request, not a deadline.
/// The point is that both would have to fail at once.
public struct ReadinessRefreshScheduler: Sendable {

    /// Identifier declared in `BGTaskSchedulerPermittedIdentifiers`.
    public static let taskIdentifier = "ss.WorkoutMirrorLive.readinessRefresh"

    /// How long to wait before the next run may begin.
    ///
    /// A request, not a promise: the system decides when it actually runs.
    public static let interval: TimeInterval = 90 * 60

    /// Registers the work. Must run before `didFinishLaunching` returns.
    ///
    /// Takes no handler on purpose. `BGTaskScheduler` wants a `sending` closure,
    /// and one that captured a handler passed in from outside could not satisfy
    /// that — the compiler has no way to know the handler is not used elsewhere.
    /// The work is fixed anyway: recalculate, then re-arm.
    public var register: @Sendable () -> Void

    /// Asks for the next run no earlier than `interval` from now.
    public var schedule: @Sendable () -> Void

    /// Creates a scheduler.
    ///
    /// - Parameters:
    ///   - register: Registers the recalculation with the system
    ///   - schedule: Requests the next run
    public init(
        register: @escaping @Sendable () -> Void,
        schedule: @escaping @Sendable () -> Void
    ) {
        self.register = register
        self.schedule = schedule
    }
}

// MARK: - DependencyKey

extension ReadinessRefreshScheduler: DependencyKey {

    public static let liveValue = ReadinessRefreshScheduler(
        register: {
            BGTaskScheduler.shared.register(
                forTaskWithIdentifier: ReadinessRefreshScheduler.taskIdentifier,
                using: nil
            ) { task in
                let job = Task {
                    @Dependency(\.trainingReadinessBackgroundManager) var manager

                    await manager.refreshNow()

                    // Re-armed from inside the run: the system holds at most one
                    // pending request per identifier, so skipping this ends the
                    // chain for good.
                    ReadinessRefreshScheduler.submitRequest()

                    task.setTaskCompleted(success: true)
                }

                // The system gives these tasks seconds, not minutes. Completion has
                // to be reported from here as well: HealthKit's query wrappers do
                // not observe cancellation, so the job can outlive the budget, and
                // expiring without reporting makes iOS grant fewer runs next time.
                task.expirationHandler = {
                    job.cancel()
                    task.setTaskCompleted(success: false)
                }
            }
        },
        schedule: {
            ReadinessRefreshScheduler.submitRequest()
        }
    )

    public static var testValue: ReadinessRefreshScheduler {
        ReadinessRefreshScheduler(
            register: unimplemented("ReadinessRefreshScheduler.register"),
            schedule: unimplemented("ReadinessRefreshScheduler.schedule")
        )
    }

    /// Hands the system one pending request for the next run.
    private static func submitRequest() {
        let request = BGAppRefreshTaskRequest(identifier: taskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: interval)

        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            #if DEBUG
            print("⚠️ [Readiness] could not schedule a background refresh: \(error)")
            #endif
        }
    }
}

// MARK: - DependencyValues

public extension DependencyValues {

    /// Schedules background recalculation of readiness.
    var readinessRefreshScheduler: ReadinessRefreshScheduler {
        get { self[ReadinessRefreshScheduler.self] }
        set { self[ReadinessRefreshScheduler.self] = newValue }
    }
}
