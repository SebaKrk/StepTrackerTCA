//
//  ProGold.swift
//  MyFitnessJournal
//
//  Created by Sebastian Ściuba on 19/11/2026.
//

import SwiftUI

/// The gold everything that sells Pro wears; it never follows the readiness colour.
enum ProGold {

    /// Gold for large shapes: borders, badges and button fills.
    static var gradient: LinearGradient {
        LinearGradient(colors: [.yellow, .orange], startPoint: .leading, endPoint: .trailing)
    }

    /// Solid gold for text-sized marks, where the pale end of the gradient would not read.
    static var accent: Color {
        .orange
    }

    /// Gold of the lock and the crown.
    static var lock: Color {
        .yellow
    }
}
