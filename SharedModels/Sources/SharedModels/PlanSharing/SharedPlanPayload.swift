//
//  SharedPlanPayload.swift
//  SharedModels
//
//  Created by Sebastian Ściuba on 13/07/2026.
//

import Foundation

/// Versioned, transport-agnostic envelope for sharing a training plan.
///
/// `schemaVersion` guards against importing a payload produced by a newer app
/// build whose plan format this build cannot parse — same freeze-then-guard
/// contract as `ExerciseType.catalogVersion`. The channel (QR / file / link)
/// makes no assumptions about this type; it only carries the encoded string.
public struct SharedPlanPayload: Codable, Equatable, Sendable {

    /// Format version of this envelope. Bumped when the payload shape changes;
    /// `SharedPlanCodec.decode` rejects payloads newer than it understands.
    public let schemaVersion: Int

    /// When the sender exported the plan. Informational — used for display/debug,
    /// not for validation (the imported copy gets its own date on the receiver).
    public let exportedAt: Date

    /// The shared training plan, carried verbatim. The receiver makes an
    /// independent copy (new identity) on import — this is a snapshot, not a link.
    public let plan: TrainingSession

    public init(schemaVersion: Int, exportedAt: Date, plan: TrainingSession) {
        self.schemaVersion = schemaVersion
        self.exportedAt = exportedAt
        self.plan = plan
    }
}
