//
//  StopwatchFeature+State.swift
//  WorkoutMirrorLive
//

import ComposableArchitecture
import Foundation

extension StopwatchFeature {

    @ObservableState
    struct State: Equatable {

        /// Determines if the stopwatch UI is currently visible.
        var isVisible: Bool = false

        /// The current elapsed time of the stopwatch in seconds.
        var time: TimeInterval = 0

        /// Indicates if the stopwatch is currently running (ticking).
        var isRunning: Bool = false

        /// True when the stopwatch is controlling the active phase timer (replaces phase panel timer).
        var isManagingPhase: Bool = false
    }

}
