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
import MapKit

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
        
        /// Primary heart rate zone info (dominant zone and duration).
        var primaryZoneInfo: PrimaryZoneInfo?
        
        /// Time spent in each heart rate zone.
        var zoneDistribution: [HeartRateZone: TimeInterval]?
        
        /// Whether the zone distribution section is expanded.
        var isExpandZone: Bool = false

        /// Per-minute HR aggregation (min/max BPM) — dane dla range BarMark chart'u stref
        /// pokazywanego nad rozwijalnym `zoneDistributionSection`. Ładowane on-appear z
        /// HealthKit przez `WorkoutSummaryLoader.heartRateSamples` + bucketing 60s.
        var hrMinuteRanges: [HRMinuteRange] = []

        /// Wybrana minuta na HR range chart'cie (`chartXSelection`). `nil` = brak selekcji.
        /// Selection wzbudza RuleMark + annotation z BPM range na danej minucie.
        var selectedMinute: Date?
        
        // MARK: - Performance Metrics
        
        /// Metabolic Equivalent of Task - workout intensity vs rest.
        var mets: Double?
        
        /// Training Impulse - training load based on time in HR zones.
        var trimp: Double?
        
        /// Heart Rate Training Stress Score - normalized training stress.
        var hrTSS: Double?
        
        /// Heart rate recovery - BPM drop 1 minute after workout.
        var hrRecovery: Int?
        
        /// Intensity Factor - workout effort relative to lactate threshold.
        var intensityFactor: Double?
        
        /// Recovery Demand - estimated recovery time based on training load and metrics.
        var recoveryDemand: RecoveryDemand?

        /// Frozen effort score for this workout (Myzone-style), read from the DB.
        /// Whole record — not just the total — so the zones section can break the
        /// points down per zone from the FROZEN `secondsByZone` (same source as the
        /// total, so the breakdown always sums to the badge). `nil` = not computed
        /// (recorded before the feature / no HR) → section hidden.
        var effortScore: WorkoutEffortScore?

        /// GymRoom class attendance for this workout (recap: place, participant count,
        /// class points, location) — `nil` when the workout wasn't part of a class, then
        /// the recap section is hidden (IOS-00104-C).
        var classParticipation: ClassParticipation?

        /// Zones section toggle: `false` shows time per zone, `true` shows the
        /// points each zone contributed. Flipped by tapping the section.
        var showZonePoints: Bool = false
        
        // MARK: - Location Data
        
        /// Full workout location data
        /// - `nil`: not loaded yet
        /// - `[]`: indoor workout (no location)
        /// - `[coordinate]`: single location (show pin)
        /// - `[coord1, coord2, ...]`: route (draw polyline)
        var routeCoordinates: [CLLocationCoordinate2D]?
        
        /// Whether location data is currently loading
        var isLoadingLocation: Bool = false
        
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
            self.primaryZoneInfo = primaryZoneInfo
            self.planScore = ActivityPlanScoreFeature.State(hkWorkoutId: workout.uuid)
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
        
        /// Intensity Factor level classification.
        var intensityFactorLevel: IntensityFactorLevel? {
            guard let intensityFactor else { return nil }
            return IntensityFactorLevel.from(value: intensityFactor)
        }
        
        /// Recovery Demand level classification.
        var recoveryDemandLevel: RecoveryDemandLevel? {
            recoveryDemand?.level
        }
        
        // MARK: - Zone Distribution
        
        /// Total time across all heart rate zones.
        var totalZoneDuration: TimeInterval {
            zoneDistribution?.values.reduce(0, +) ?? 0
        }
        
        // MARK: - Location Helpers
        
        /// Location type based on route coordinates count
        var locationType: WorkoutLocationType? {
            guard let coordinates = routeCoordinates else { return nil }
            return coordinates.isEmpty ? .indoor : .outdoor
        }
        
        /// Whether to show route on map (2+ coordinates)
        var shouldShowRoute: Bool {
            guard let coordinates = routeCoordinates else { return false }
            return coordinates.count >= 2
        }
        
        /// Whether to show single location pin (exactly 1 coordinate)
        var shouldShowLocation: Bool {
            guard let coordinates = routeCoordinates else { return false }
            return coordinates.count == 1
        }
    }
}

