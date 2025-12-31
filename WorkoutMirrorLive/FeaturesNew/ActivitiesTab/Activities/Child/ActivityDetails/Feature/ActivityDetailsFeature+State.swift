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
        var color: Color = .clear
        
        // MARK: - Workout Data
        
        /// The workout being displayed.
        var workout: HKWorkout
        
        /// User's maximum heart rate for zone calculations.
        var maxHeartRate: Double
        
        /// Primary heart rate zone info (dominant zone and duration).
        var primaryZoneInfo: PrimaryZoneInfo?
        
        /// Time spent in each heart rate zone.
        var zoneDistribution: [HeartRateZone: TimeInterval]?
        
        /// Whether the zone distribution section is expanded.
        var isExpandZone: Bool = false
        
        // MARK: - Performance Metrics
        
        /// Metabolic Equivalent of Task - workout intensity vs rest.
        /// Values: <3 light, 3-6 moderate, 6-9 vigorous, 9+ very vigorous.
        var mets: Double?
        
        /// Training Impulse - training load based on time in HR zones.
        /// Values: 50-100 light, 100-200 moderate, 200-300 hard, 300+ very hard.
        var trimp: Double?
        
        /// Heart Rate Training Stress Score - normalized training stress.
        /// 100 = 1 hour at lactate threshold. Used for recovery estimation.
        var hrTSS: Double?
        
        /// Heart rate recovery - BPM drop 1 minute after workout.
        /// Values: <12 poor, 12-20 average, 20-30 good, 30-40 very good, 40+ excellent.
        var hrRecovery: Int?
        
        // MARK: - Init
        
        init(workout: HKWorkout, maxHeartRate: Double, primaryZoneInfo: PrimaryZoneInfo? = nil) {
            self.workout = workout
            self.maxHeartRate = maxHeartRate
            self.primaryZoneInfo = primaryZoneInfo
        }
    }
}
