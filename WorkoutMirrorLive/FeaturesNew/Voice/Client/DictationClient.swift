//
//  DictationClient.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 28/11/2026.
//

import ComposableArchitecture
import Foundation

/// The boundary every dictation goes through; speech is recognized on the device, nothing is recorded.
@DependencyClient
struct DictationClient: Sendable {

    /// Opens the microphone and streams the transcript until the stream ends or its task is cancelled.
    var start: @Sendable (_ locale: Locale, _ hints: [String]) -> AsyncThrowingStream<DictationEvent, any Error> = { _, _ in
        AsyncThrowingStream { $0.finish() }
    }

    /// Closes the microphone; the stream still delivers the final transcript, then ends.
    var finish: @Sendable () async -> Void
}

extension DependencyValues {

    /// On-device dictation.
    var dictationClient: DictationClient {
        get { self[DictationClient.self] }
        set { self[DictationClient.self] = newValue }
    }
}

extension DictationClient: DependencyKey {

    // MARK: - Live Value

    /// One service per process.
    static let liveValue: DictationClient = {
        let service = DictationService()
        return DictationClient(
            start: { locale, hints in service.events(locale: locale, hints: hints) },
            finish: { await service.finish() }
        )
    }()

    // MARK: - Preview Value

    /// Dictates one fixed sentence.
    static var previewValue: DictationClient {
        DictationClient(start: { _, _ in
            AsyncThrowingStream { continuation in
                continuation.yield(.listening)
                continuation.yield(.transcript("W WOD 2 drabinka 15-12-9"))
            }
        }, finish: {})
    }

    // MARK: - Test Value

    /// Fails the test if the reducer starts dictation unexpectedly.
    static var testValue: DictationClient {
        DictationClient(start: { _, _ in
            reportIssue("DictationClient.start is unimplemented")
            return AsyncThrowingStream { $0.finish() }
        }, finish: {
            reportIssue("DictationClient.finish is unimplemented")
        })
    }
}
