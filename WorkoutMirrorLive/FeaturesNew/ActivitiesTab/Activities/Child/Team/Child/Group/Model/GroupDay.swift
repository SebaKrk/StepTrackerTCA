//
//  GroupDay.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 27/10/2026.
//

import Foundation

/// One day of the week strip on the group screen.
struct GroupDay: Identifiable, Equatable {

    /// Day id (`yyyy-MM-dd`) of the group's plan.
    let id: String

    /// Start of the day — for the weekday name and date shown.
    let date: Date
}
