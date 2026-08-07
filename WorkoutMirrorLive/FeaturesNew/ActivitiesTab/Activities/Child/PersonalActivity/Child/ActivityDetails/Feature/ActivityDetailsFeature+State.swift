//
//  ActivityDetailsFeature+State.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 31/12/2025.
//

import ComposableArchitecture
import SharedModels
import HealthKit
import SwiftUI

/// Implementation of `ActivityDetailsFeature` state.
extension ActivityDetailsFeature {
    
    @ObservableState
    struct State {
        
        // MARK: - Shared
        
        /// Color representing training readiness level, shared across features.
        @Shared(.inMemory(.readinessLevelColor))
        var color: Color = .gray
        
        // MARK: - Workout Data

        /// The workout being displayed.
        var workout: HKWorkout

        /// User's maximum heart rate for zone calculations.
        var maxHeartRate: Double

        /// `viewDidAppear` idempotency — loads fire only on the first appearance.
        var hasAppeared = false

        // MARK: - Children

        /// HR zones + effort points + per-minute HR chart (IOS-00105).
        var heartRateZones: HeartRateZonesFeature.State

        /// Performance metric cards; also feeds METs to the energy section (IOS-00105).
        var performanceMetrics: PerformanceMetricsFeature.State

        /// GPS route / single pin; loaded ONLY when the workout has no class recap
        /// — mutual exclusion, the parent decides (IOS-00105).
        var workoutRoute: WorkoutRouteFeature.State

        /// GymRoom class recap: place, class points, gym map (IOS-00104-C); the map
        /// mounts on the parent's `mountMap` command once the gate below empties.
        var classRecap: ClassRecapFeature.State

        /// Loads that must finish before the recap map may mount. `Map` has to enter a
        /// settled layout — mounting it while sections above still appear/disappear hands
        /// MapKit a zero-sized drawable (`CAMetalLayer width=0`) and hangs the renderer.
        /// Children report `delegate(.didFinishLoading)`; the parent checks them off here.
        var pendingRecapMapLoads: Set<RecapMapLoad> = []

        enum RecapMapLoad: Hashable {
            case location
            case metrics
            case recap
            case zones
        }

        // MARK: - Plan Score

        /// WOD results linked to this workout via a training plan.
        var planScore: ActivityPlanScoreFeature.State

        // MARK: - Destination

        /// Presentation state for navigation destinations.
        @Presents var destination: Destination.State?

        // MARK: - Init

        init(workout: HKWorkout, maxHeartRate: Double, primaryZoneInfo: PrimaryZoneInfo? = nil) {
            self.workout = workout
            self.maxHeartRate = maxHeartRate
            self.heartRateZones = HeartRateZonesFeature.State(
                workout: workout,
                maxHeartRate: maxHeartRate,
                primaryZoneInfo: primaryZoneInfo
            )
            self.performanceMetrics = PerformanceMetricsFeature.State(
                workout: workout,
                maxHeartRate: maxHeartRate
            )
            self.workoutRoute = WorkoutRouteFeature.State(workout: workout, maxHeartRate: maxHeartRate)
            self.classRecap = ClassRecapFeature.State(workout: workout)
            self.planScore = ActivityPlanScoreFeature.State(hkWorkoutId: workout.uuid)
        }
    }
}

