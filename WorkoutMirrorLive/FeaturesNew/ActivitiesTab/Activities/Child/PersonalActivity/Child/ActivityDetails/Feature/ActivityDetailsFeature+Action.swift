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
        }
        
        case view(View)
        
        /// View-triggered actions.
        enum View {
            
            /// Called when the view appears on screen.
            case viewDidAppear

            /// Manual entry: user tap'nął "Dodaj plan" — opens TemplatePicker sheet.
            /// Dostępne tylko gdy `planScore.loadState == .notFound` (workout bez podpiętego planu).
            case linkTemplateTapped

            /// Manual entry: user tap'nął "Edytuj wynik" — ładuje istniejący WorkoutPlanScore + summary
            /// i pushuje SummaryFeature w edit mode z pre-filled resultInputs.
            /// Dostępne tylko gdy `planScore.loadState == .loaded(score)` (workout ma już zapisany plan).
            case editExistingScoreTapped
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
