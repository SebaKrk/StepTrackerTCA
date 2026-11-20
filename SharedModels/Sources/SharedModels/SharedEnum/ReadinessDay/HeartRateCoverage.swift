//
//  HeartRateCoverage.swift
//  SharedModels
//
//  Created by Sebastian Ściuba on 13/11/2026.
//

import Foundation

/// How much of a window heart rate samples actually cover.
///
/// Deliberately not a date range. A Watch worn until 21:00 and again from 08:00
/// leaves two clusters eleven hours apart, and the span between them says nothing
/// about the night in between — which is exactly the night being asked about.
public struct HeartRateCoverage: Sendable, Equatable {

    /// Time genuinely covered by samples, with gaps excluded.
    public let covered: TimeInterval

    /// When the last sample in the window ended.
    public let lastSample: Date

    /// Creates a coverage summary.
    ///
    /// - Parameters:
    ///   - covered: Time covered by samples, gaps excluded
    ///   - lastSample: End of the last sample
    public init(covered: TimeInterval, lastSample: Date) {
        self.covered = covered
        self.lastSample = lastSample
    }
}
