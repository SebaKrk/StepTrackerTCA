//
//  ActivityDetailsFeature+Action.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 31/12/2025.
//

import ComposableArchitecture
import Foundation
import SharedModels
import MapKit

/// Implementation of `ActivityDetailsFeature` actions.
extension ActivityDetailsFeature {
    
    @CasePathable
    enum Action: ViewAction {
        
        case `internal`(Internal)
        
        /// Internal actions for state management and data loading.
        enum Internal {
            
            /// Heart rate zone distribution loaded successfully.
            case zoneDistributionLoaded([HeartRateZone: TimeInterval])
            
            /// All performance metrics loaded.
            /// - Parameters:
            ///   - mets: Metabolic Equivalent of Task
            ///   - trimp: Training Impulse score
            ///   - hrTSS: Heart Rate Training Stress Score
            ///   - hrRecovery: Heart rate recovery after 1 minute (bpm drop)
            ///   - intensityFactor: Workout effort relative to lactate threshold
            ///   - recoveryDemand: Estimated recovery time
            case metricsLoaded(mets: Double?, trimp: Double?, hrTSS: Double?, hrRecovery: Int?, intensityFactor: Double?, recoveryDemand: RecoveryDemand?)
            
            /// Toggles expansion state of heart rate zones section.
            case zoneExpand(Bool)
            
            /// Triggers loading of heart rate zone distribution.
            case loadZoneDistribution
            
            /// Triggers loading of all performance metrics.
            case loadMetrics
            
            /// Route/location data loaded successfully (empty array = indoor workout)
            case locationDataLoaded([CLLocationCoordinate2D])

            /// Triggers loading of route/location data
            case loadLocationData

            /// Manual-entry: WorkoutSummary + hrBuffer załadowane z HealthKit dla wybranego template'a.
            /// Następny krok: open SummaryFeature destination z manual init.
            case manualSummaryLoaded(summary: WorkoutSummary, trainingSession: TrainingSession, hrBuffer: [(date: Date, bpm: Double)])

            /// Manual-entry: ładowanie WorkoutSummary z HealthKit failed (brak HR samples, brak permission, etc.).
            case manualSummaryLoadFailed

            /// Edit-mode: WorkoutSummary + hrBuffer + istniejące resultInputs załadowane.
            /// Następny krok: open SummaryFeature destination w edit mode (pre-filled wynikami).
            case editScoreLoaded(summary: WorkoutSummary, trainingSession: TrainingSession, hrBuffer: [(date: Date, bpm: Double)], existingResults: [WorkoutSessionResult])

            /// Edit-mode: ładowanie failed (TrainingSession nie istnieje, brak HR samples, etc.).
            case editScoreLoadFailed

            /// Triggers fetch HR samples z HealthKit + bucketing do `[HRMinuteRange]`.
            case loadHRMinuteRanges

            /// HR samples załadowane i pogrupowane po minutach — zasilenie range BarMark chart'u.
            case hrMinuteRangesLoaded([HRMinuteRange])

            /// Triggers fetch of the stored effort score for this workout.
            case loadEffortPoints

            /// Stored effort score loaded — `nil` for workouts recorded before the
            /// feature shipped (no backfill; the section is hidden for `nil`).
            case effortScoreLoaded(WorkoutEffortScore?)

            /// Triggers fetch of the stored class participation (recap) for this workout.
            case loadClassParticipation

            /// Stored class participation loaded — `nil` when the workout wasn't part of
            /// a GymRoom class (the recap section is hidden for `nil`).
            case classParticipationLoaded(ClassParticipation?)
        }
        
        case view(View)
        
        /// View-triggered actions.
        enum View {
            
            /// Called when the view appears on screen.
            case viewDidAppear

            /// Called when user taps zone disclosure button.
            case zoneDiscusserButtonTapped(Bool)

            /// Toggles the zones section between time-per-zone and points-per-zone.
            case zonePointsToggled

            /// Opens metric details screen
            case openMetricDetails(MetricTypeDetails)

            /// Manual entry: user tap'nął "Podpnij plan" — opens TemplatePicker sheet.
            /// Dostępne tylko gdy `planScore.loadState == .notFound` (workout bez podpiętego planu).
            case linkTemplateTapped

            /// Manual entry: user tap'nął "Edytuj wynik" — ładuje istniejący WorkoutPlanScore + summary
            /// i pushuje SummaryFeature w edit mode z pre-filled resultInputs.
            /// Dostępne tylko gdy `planScore.loadState == .loaded(score)` (workout ma już zapisany plan).
            case editExistingScoreTapped

            /// User scrub'nął HR range chart — `chartXSelection` zwraca wybraną minutę (lub `nil` przy
            /// deselect tap-poza). Zasila RuleMark + annotation z BPM range tej minuty.
            case minuteSelected(Date?)
        }
        
        // MARK: - Plan Score

        /// Child feature actions for loading WOD results linked to this workout.
        case planScore(ActivityPlanScoreFeature.Action)

        // MARK: - Destination

        /// Handles navigation destinations within this feature.
        case destination(PresentationAction<Destination.Action>)
    }
}
