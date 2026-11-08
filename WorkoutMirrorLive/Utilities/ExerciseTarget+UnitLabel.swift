//
//  ExerciseTarget+UnitLabel.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 08/11/2026.
//

import Foundation
import SharedModels

extension ExerciseTarget {

    /// Unit shown beside an entered value; a movement without a target counts reps.
    ///
    /// Lives in the app, not SharedModels: the package can localize, but keeping every
    /// translated word in one catalog beats splitting them across two. The unit symbols
    /// read the same in every language, so they stay as written.
    static func unitLabel(for target: ExerciseTarget?) -> String {
        switch target {
        case .reps, .none:
            String(localized: "reps", bundle: .main)
        case .calories:
            "cal"
        case .meters:
            "m"
        case .seconds:
            "s"
        case .minutes:
            "min"
        case .rounds:
            // Historic key; renaming it to "rounds" would orphan the translation.
            String(localized: "rund", bundle: .main)
        case .laps:
            String(localized: "laps", bundle: .main)
        }
    }
}
