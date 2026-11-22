//
//  ActivityDetailsFeature+Action.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 31/12/2025.
//

import ComposableArchitecture
import Foundation
import SharedModels

/// Implementation of `ActivityDetailsFeature` actions.
extension ActivityDetailsFeature {
    
    @CasePathable
    enum Action: ViewAction {
        
        case `internal`(Internal)
        
        /// Internal actions for state management and data loading.
        enum Internal {
            
            /// The workout summary for the picked plan finished loading; success opens the results screen.
            case summaryLoaded(Result<(summary: WorkoutSummary,
                                       trainingSession: TrainingSession,
                                       hrBuffer: [(date: Date, bpm: Double)],
                                       existingResults: [WorkoutSessionResult]),
                               any Error>)
            
            /// The linked plan is gone from the local database — the user picks a plan to re-link.
            case linkedPlanMissing
        }
        
        case view(View)
        
        /// View-triggered actions.
        enum View {
            
            /// Called when the view appears on screen.
            case viewDidAppear

            /// Manual entry: user tap'nął "Dodaj plan" — opens TemplatePicker sheet.
            /// Dostępne tylko gdy `planScore.loadState == .notFound` (workout bez podpiętego planu).
            case linkTemplateTapped

            /// Rounds card tapped — pushes the rounds analysis screen.
            case roundsCardTapped
        }

        // MARK: - Children

        /// HR zones + effort points + HR chart child; loads report via
        /// `delegate(.didFinishLoading)` into the parent's recap-map gate.
        case heartRateZones(HeartRateZonesFeature.Action)

        /// Performance-metrics child; card taps arrive as
        /// `delegate(.openMetricDetails)` and open the parent's destination.
        case performanceMetrics(PerformanceMetricsFeature.Action)

        /// GPS-route child; `.load` is sent ONLY when the recap fetch came back
        /// empty (class workouts never have a route).
        case workoutRoute(WorkoutRouteFeature.Action)

        /// Class-recap child; the parent reacts to `delegate(.didLoad(hasRecap:))`
        /// (route exclusion) and sends `.mountMap` once the recap-map gate empties.
        case classRecap(ClassRecapFeature.Action)

        // MARK: - Plan Score

        /// Child feature actions for loading WOD results linked to this workout.
        case planScore(ActivityPlanScoreFeature.Action)

        // MARK: - Destination

        /// Handles navigation destinations within this feature.
        case destination(PresentationAction<Destination.Action>)
    }
}
