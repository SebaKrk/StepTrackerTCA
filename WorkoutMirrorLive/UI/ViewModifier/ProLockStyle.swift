//
//  ProLockStyle.swift
//  MyFitnessJournal
//
//  Created by Sebastian Ściuba on 19/11/2026.
//

import Foundation

/// How locked content says that it needs Pro.
enum ProLockStyle {

    /// A lock alone; the whole surface opens the offer. For rows that repeat.
    case badge

    /// A lock, a title and an unlock button. For a single tall card.
    case prompt
}
