//
//  ScanRunOutcome.swift
//  HealthHub
//
//  Created by Sebastian Ściuba on 07/11/2026.
//

import Foundation
import SharedModels

#if DEBUG

/// How a recorded scan ended.
public enum ScanRunOutcome: Sendable {

    /// The model returned a board that decoded against the schema.
    case success(ScannedBoard)

    /// The parse threw; the error is carried as text because `any Error` is not `Sendable`.
    case failure(String)
}

#endif
