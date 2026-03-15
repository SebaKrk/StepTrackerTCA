//
//  LiveSessionFeature+Action.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 17/01/2026.
//

import ComposableArchitecture
import Foundation
import SharedModels


/// Implementation of `LiveSessionFeature` action
extension LiveSessionFeature {
    
    @CasePathable
    enum Action: ViewAction {
        
        // MARK: - Actions

        /// Updates the current workout metrics with new data.
        /// Triggered whenever a new `WorkoutMetrics` is received from the workout stream.
        case workoutMetrics(WorkoutMetrics)
        
        /// Sets the maximum heart rate (HR max) for the current session.
        /// Usually calculated at the beginning of the session using age and sex.
        case setupMaxHeartRate(Int)
        
        /// Starts streaming workout metrics (heart rate, active energy, etc.) from the session client.
        case startWorkoutMetricsStream
        
        /// Calculates the current heart rate zone based on the latest heart rate and HR max.
        case calculateHeartRateZone(Int, Int)
        
        /// Calculates the user's current heart rate as a percentage of the HR max.
        case calculateHeartRatePercentage(Int, Int)
        
        /// Updates the session's average and maximum heart rate with the provided values.
        case updateSessionHeartRateStats(average: Int, max: Int)

        /// Calculates session-level heart rate statistics based on a new heart rate reading.
        case calculateSessionHeartRateStats(Int)
        
        // MARK: - Live Activity (Child Reducer)

        /// Delegates to LiveActivityFeature child reducer
        case liveActivity(LiveActivityFeature.Action)

        /// Delegates to user StopwatchFeature (toolbar button).
        case userStopwatch(StopwatchFeature.Action)

        /// Delegates to phase StopwatchFeature (phase timer management).
        case phaseStopwatch(StopwatchFeature.Action)

        // MARK: - Phase Panel (Child Reducer)

        /// Initialises the phase panel from the given phases.
        /// Pass an empty array (or call when `trainingSession` is nil) to hide the panel.
        case setupPhasePanel([WorkoutPhase])

        /// Delegates to PhasePanelFeature child reducer
        case phasePanel(PhasePanelFeature.Action)
        
        // MARK: - View Actions
        
        case view(View)
        
        enum View {

            /// Action triggered when the view appears on the screen.
            case viewDidAppear
        }
    }
    
}
