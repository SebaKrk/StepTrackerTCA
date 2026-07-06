//
//  SummaryState.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 30/08/2025.
//

import Foundation

enum SummaryState {

    /// Loading the workout from the local router cache (iPhone-standalone) —
    /// bounded 5×1s retry covers the finishWorkout→cache broadcast race.
    /// The old `.saving` case ("waiting for Watch confirmation") was removed in
    /// IOS-00098-E along with the cross-device waiting machinery.
    case loading

    /// Indicates that the summary view has successfully loaded the workout data.
    case successfullyLoaded

    /// Error has occurred when loading the view.
    case failed
}
