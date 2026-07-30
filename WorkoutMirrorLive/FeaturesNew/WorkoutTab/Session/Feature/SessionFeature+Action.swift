//
//  SessionFeature+Action.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 21/09/2025.
//

import ComposableArchitecture
import HealthHub
import SharedModels

/// Implementation of `SessionFeature` action
extension SessionFeature {
    
    @CasePathable
    enum Action: ViewAction {
        
        // MARK: - Actions
        
        /// Drives the top-level navigation between the countdown, live session, and summary screens.
        ///
        /// Transitioning to `.session` starts all long-running effects (Watch event stream,
        /// metrics stream, Live Activity, tick timer). Transitioning to `.summary` cancels them.
        case sessionViewStateChange(SessionState)

        /// Triggers an async lookup of the user's age and biological sex from HealthKit,
        /// then calculates and applies the maximum heart rate for the current session.
        case makeCalculationForSession

        /// Applies the calculated maximum heart rate to `LiveSessionFeature` state
        /// and, if a session is active, forwards the updated value to Watch
        /// so it can recalculate HR zones immediately.
        case setMaxHR(Int)

        /// Fired once per second by the internal clock effect while the workout is running.
        ///
        /// Reads `state.controls.elapsedTime` and sends `.workoutTick` to Watch.
        case watchTickEffect

        /// Received when the paired Apple Watch sends a `WatchWorkoutEvent` during an active session.
        case watchEventReceived(WatchWorkoutEvent)

        /// Mirroring-link status changed (IOS-00098-G): `.lost` mid-workout raises the
        /// banner and suspends ticks; `.connected` (system auto-reconnect delivered a
        /// fresh mirrored session) clears the banner and resumes ticks.
        case watchConnectionStatusChanged(WatchMirroringConnectionStatus)

        /// Presentation plumbing for the "end on Watch" instruction alert.
        /// `endAnyway` closes the iPhone side when the Watch is physically
        /// unavailable — the only exit from an otherwise dead-locked session.
        case connectionLostAlert(PresentationAction<ConnectionLostAlertAction>)

        /// Presentation plumbing for the "class still running" confirmation shown when
        /// the user taps End while connected to a GymRoom class. `leaveAnyway` proceeds.
        case classActiveAlert(PresentationAction<ClassActiveAlertAction>)

        /// Runs the actual end-of-workout flow. Split out of `endWorkoutButtonTapped`
        /// so both the normal path and the class-active alert's "Wyjdź" reach the same
        /// mode-aware teardown without duplication.
        case proceedEndWorkout

        /// The `.workoutEnded` HK send failed/timed out BEFORE the system reported a
        /// disconnect — instead of a false-success dismiss, show the "end on Watch"
        /// instruction and keep the session alive (IOS-00098 review, cluster D).
        case endDeliveryFailed

        /// Sets the workout mode (Watch-primary vs iPhone-standalone) determined
        /// in `viewDidAppear` based on Watch availability.
        case setWorkoutMode(WorkoutMode)

        /// Watch-primary mode: subscribes to `TrainingManager.mirroredSessionStartedStream`
        /// to detect when Apple Watch actually started the mirrored session. On first emit,
        /// transitions `sessionState` from `.waitingForWatch` to `.countdown`.
        /// Internal action — dispatched from `viewDidAppear` after `startWatchWorkout` succeeds.
        case subscribeMirroredSessionStarted

        /// `PauseWorkoutIntent` from Live Activity / Lock Screen posted the
        /// `workoutPauseRequested` notification. Routes to the same flow as on-screen
        /// pause (`controls.view.mainControlButtonTapped`).
        case intentPauseRequested

        /// `ResumeWorkoutIntent` notification handler. See `intentPauseRequested`.
        case intentResumeRequested

        /// `EndWorkoutIntent` notification handler. Routes to on-screen end flow
        /// (`controls.view.endWorkoutButtonTapped`) — reuses the HK-channel `.workoutEnded`
        /// send for Watch-primary mode.
        case intentEndRequested

        // MARK: - View Actions
        
        case view(View)
        
        enum View {
                    
            /// Action triggered when the view appears on the screen.
            case viewDidAppear
            
            ///
            //case closeButtonTapped
            
            /// Opens the heart rate zone info sheet.
            case heartRateZoneButtonTapped
            
            /// Timer button tapped in toolbar
            case timerButtonTapped

            /// IPAD-0087 Gym Room: toolbar icon (next to HR zones) — toggles sheet visibility.
            /// First tap: create state + show sheet. Subsequent taps: only show the sheet
            /// (state exists, broadcast continues).
            case joinLiveClassToolbarButtonTapped

            /// IPAD-0087 Gym Room: sheet closed by the user (swipe-down / X). The
            /// broadcast CONTINUES, state is not cleared — we only hide the view.
            /// Moved into View actions (was a plain action) — dispatched from the sheet
            /// binding, per the `@ViewAction` no-direct-`store.send` rule.
            case joinLiveClassSheetDismissed

        }
        
        // MARK: - Destination
        
        /// Action to handle navigation destinations within this feature.
        case destination(PresentationAction<Destination.Action>)
        
        // MARK: - Child

        /// Delegates to `CountDownFeature` — handles the pre-workout countdown.
        case countDown(CountDownFeature.Action)

        /// Delegates to `LiveSessionFeature` — manages real-time metrics, Live Activity, and phase panel.
        case live(LiveSessionFeature.Action)

        /// Delegates to `ControlsFeature` — handles pause/resume/end and elapsed time.
        case controls(ControlsFeature.Action)

        /// Delegates to `SummaryFeature` — displays post-workout summary and save/discard actions.
        case summary(SummaryFeature.Action)

        /// IPAD-0087 Gym Room: delegates to `JoinLiveClassFeature` — persistent HR broadcast.
        case joinLiveClass(JoinLiveClassFeature.Action)
        
    }
    
}
