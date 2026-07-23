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

        /// Mirroring-link status forwarded by `SessionFeature` (IOS-00098-G).
        /// Stores the flag and pushes an immediate Live Activity update so
        /// Dynamic Island / Lock Screen flag stale metrics right away.
        case setWatchConnectionLost(Bool)

        /// BLE strap disconnect reason forwarded by `SessionFeature` (out of range
        /// / device off). Colours the stale banner's message. `nil` on CB reconnect.
        case setSensorDisconnectReason(SensorDisconnectReason?)
        
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

        /// Resets the displayed heart rate to 0. Used by the Watch HR watchdog timer
        /// when no reading has been received for an extended period — bypasses the
        /// HealthKit-zero guard in `.workoutMetrics` which would otherwise preserve
        /// the last known value.
        case resetHeartRate

        /// 1 s heartbeat forwarded from `SessionFeature.watchTickEffect` (IOS-00100-B).
        /// Evaluates BLE-sensor freshness: no real sample for longer than
        /// `sensorStaleThreshold` flips `isSensorStale` (banner + greyed HR). No-op
        /// on the Watch path (`lastFreshSampleDate` stays `nil` there).
        case sensorFreshnessTick
        
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

            /// Action triggered when the view disappears from the screen.
            case viewDidDisappear
        }
    }
    
}
