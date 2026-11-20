//
//  ScanFailure.swift
//  SharedModels
//
//  Created by Sebastian Ściuba on 17/11/2026.
//

import Foundation

/// User-presentable description of a failed scan, ready for `ContentUnavailableView`.
public struct ScanFailure: Equatable, Sendable {

    /// Short headline naming what went wrong.
    public let title: String

    /// One sentence saying what happened and what the user can do next.
    public let message: String

    /// Whether repeating the same request can plausibly succeed today.
    ///
    /// A used-up daily allowance or an oversized plan fails identically on every
    /// retry, so those screens offer manual entry instead of a pointless button.
    public let canRetry: Bool

    public init(title: String, message: String, canRetry: Bool) {
        self.title = title
        self.message = message
        self.canRetry = canRetry
    }
}
