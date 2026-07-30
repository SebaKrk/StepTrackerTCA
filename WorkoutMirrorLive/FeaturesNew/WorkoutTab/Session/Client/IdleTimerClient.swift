//
//  IdleTimerClient.swift
//  MyFitnessJournal
//

import ComposableArchitecture
import UIKit

struct IdleTimerClient {
    var setDisabled: @Sendable (Bool) async -> Void
}

extension DependencyValues {
    var idleTimer: IdleTimerClient {
        get { self[IdleTimerClientKey.self] }
        set { self[IdleTimerClientKey.self] = newValue }
    }
}

private enum IdleTimerClientKey: DependencyKey {
    static let liveValue = IdleTimerClient(
        setDisabled: { disabled in
            await MainActor.run {
                UIApplication.shared.isIdleTimerDisabled = disabled
            }
        }
    )
    static let testValue = IdleTimerClient(
        setDisabled: { _ in }
    )
}
