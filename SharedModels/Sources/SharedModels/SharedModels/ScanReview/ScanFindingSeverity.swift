//
//  ScanFindingSeverity.swift
//  SharedModels
//
//  Created by Sebastian Ściuba on 29/10/2026.
//

import Foundation

/// How a finding blocks the scan flow and how it closes.
public enum ScanFindingSeverity: String, Codable, Sendable, CaseIterable {

    /// The plan cannot be saved at all; the scan ends with an error.
    case hard

    /// A rule on the plan fails; closes by itself once an edit makes the rule pass.
    case needsFix

    /// The model was unsure or a default was applied; closes by "OK" or by editing the block.
    case needsConfirmation

    /// Something was fixed automatically; shown, never blocks.
    case info
}
