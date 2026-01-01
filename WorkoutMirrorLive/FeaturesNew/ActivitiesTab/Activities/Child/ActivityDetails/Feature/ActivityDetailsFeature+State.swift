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
        var mets: Double?
        
        /// Training Impulse - training load based on time in HR zones.
        var trimp: Double?
        
        /// Heart Rate Training Stress Score - normalized training stress.
        var hrTSS: Double?
        
        /// Heart rate recovery - BPM drop 1 minute after workout.
        var hrRecovery: Int?
        
        // MARK: - Init
        
        init(workout: HKWorkout, maxHeartRate: Double, primaryZoneInfo: PrimaryZoneInfo? = nil) {
            self.workout = workout
            self.maxHeartRate = maxHeartRate
            self.primaryZoneInfo = primaryZoneInfo
        }
        
        // MARK: - Domain Models
        
        /// METs intensity classification.
        var metsIntensity: METsIntensity? {
            guard let mets else { return nil }
            return METsIntensity.from(value: mets)
        }
        
        /// TRIMP training load classification.
        var trimpLevel: TRIMPLevel? {
            guard let trimp else { return nil }
            return TRIMPLevel.from(value: trimp)
        }
        
        /// hrTSS stress level classification.
        var hrTSSLevel: HRTSSLevel? {
            guard let hrTSS else { return nil }
            return HRTSSLevel.from(value: hrTSS)
        }
        
        /// HR Recovery fitness level classification.
        var hrRecoveryLevel: HRRecoveryLevel? {
            guard let hrRecovery else { return nil }
            return HRRecoveryLevel.from(value: hrRecovery)
        }
        
        // MARK: - Zone Distribution
        
        /// Total time across all heart rate zones.
        var totalZoneDuration: TimeInterval {
            zoneDistribution?.values.reduce(0, +) ?? 0
        }
    }
}
