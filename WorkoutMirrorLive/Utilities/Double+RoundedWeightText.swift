//
//  Double+RoundedWeightText.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 08/11/2026.
//

import Foundation

extension Double {

    /// A load for display: 80 reads as "80", 82.5 as "82.5".
    ///
    /// Display only, and named for the rounding it does. A value that gets stored or
    /// compared keeps full precision instead — rounding 102.25 to 102.2 once turned a
    /// PR into a tie; see `PREntryEditorFeature.State.weightText(from:)`.
    var roundedWeightText: String {
        truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", self)
            : String(format: "%.1f", self)
    }
}
