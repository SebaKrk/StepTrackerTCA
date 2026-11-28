//
//  SideBlockOrder.swift
//  SharedModels
//
//  Created by Sebastian Ściuba on 28/11/2026.
//

import Foundation

/// Which part of a warm-up or cool-down is done first.
public enum SideBlockOrder: String, Codable, Sendable, CaseIterable {

    /// The block (e.g. a Tabata) comes before the written notes.
    case blockFirst

    /// The written notes (mobility, stretching) come before the block.
    case notesFirst
}
