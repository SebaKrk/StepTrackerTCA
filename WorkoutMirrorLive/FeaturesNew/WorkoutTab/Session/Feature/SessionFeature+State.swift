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
