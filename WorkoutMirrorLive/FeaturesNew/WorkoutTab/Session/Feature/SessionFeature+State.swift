//
//  SessionFeature+State.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 21/09/2025.
//

import ComposableArchitecture
import SharedModels

/// Implementation of `SessionFeature` state
extension SessionFeature {
    
    @ObservableState
    struct State {
        
        // MARK: - Properties
        
        ///
        var sessionState: SessionState = .countdown

        /// Determines whether Watch or iPhone owns the active HKWorkoutSession.
        /// Set during `viewDidAppear` based on Watch availability.
        var workoutMode: WorkoutMode = .iPhoneStandalone

        ///
        var selectedWorkout: WorkoutType

        /// The training plan to execute, if any. `nil` for free workouts.
        var trainingSession: TrainingSession? = nil

        // MARK: - Watch Connection (IOS-00098-G)

        /// `true` while the HealthKit mirroring link with the Watch-primary session is
        /// down (`didDisconnectFromRemoteDeviceWithError` mid-workout). The workout keeps
        /// running on the Watch — UI shows a banner, ticks are suspended, and the End
        /// button routes to an instruction alert instead of sending into a dead link.
        /// Cleared when the system reconnect delivers a fresh mirrored session.
        var isWatchConnectionLost: Bool = false

        /// Instruction alert shown when the user taps End while the link is down —
        /// per Apple docs the app should tell the user to end the workout on the Watch.
        @Presents var connectionLostAlert: AlertState<Never>?

        // MARK: - Destination

        /// destination from WorkoutFeature
        @Presents var destination: Destination.State?

        // MARK: - Gym Room (IPAD-0087)

        /// Trwały state broadcastu HR do iPada. Niezależny od `isJoinLiveClassSheetPresented`
        /// — sheet to tylko widok kontrolny. Po `joinTapped` sheet znika ale broadcast trwa,
        /// ikona toolbar pokazuje connected. Auto-cleanup gdy session przechodzi w `.summary`.
        var joinLiveClass: JoinLiveClassFeature.State?

        /// Sheet visibility — kontrolowany niezależnie od `joinLiveClass` lifetime.
        var isJoinLiveClassSheetPresented: Bool = false

        // MARK: - Child

        ///
        var countDown: CountDownFeature.State = .init()

        ///
        var live: LiveSessionFeature.State = .init()

        ///
        var controls: ControlsFeature.State = .init()

        ///
        var summary: SummaryFeature.State = .init()
    }

}
