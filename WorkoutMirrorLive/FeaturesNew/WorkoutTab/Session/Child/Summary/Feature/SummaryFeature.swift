//
//  SummaryFeature.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 30/08/2025.
//

import ComposableArchitecture
import HealthKit
import IssueReporting
import SharedModels
import Foundation

@Reducer
struct SummaryFeature {

    // MARK: - Dependency

    @Dependency(\.sessionClient) var client
    @Dependency(\.workoutPlanScoreClient) var workoutPlanScoreClient
    @Dependency(\.dismiss) var dismiss
    
    // MARK: - Reducer
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
                
                // MARK: - Action
            case let .changeViewState(viewState):
                state.viewState = viewState
                return .none
                
            case .checkSummary:
                return .run { send in
                    let summary = await client.getWorkoutSummary()
                    await send(.summaryLoaded(summary))
                }
                
            case let .setTrainingSession(trainingSession):
                state.trainingSession = trainingSession
                let workouts = trainingSession?.workouts ?? []
                state.resultInputs = workouts.map { WorkoutSessionResult(name: $0.name, description: $0.snapshotDescription) }
                state.showResults = Array(repeating: false, count: workouts.count)
                state.showNotes = Array(repeating: false, count: workouts.count)
                return .none

            case let .summaryLoaded(summary):
                state.summary = summary
                
                if summary.workout != nil {
                    state.viewState = .successfullyLoaded
                    return .cancel(id: SummaryFeatureCancelID.retry)
                } else {
                    state.viewState = .loading
                    return .run { send in
                        try? await Task.sleep(for: .milliseconds(3000))
                        await send(.checkSummary)
                    }
                    .cancellable(id: SummaryFeatureCancelID.retry, cancelInFlight: true)
                }
                
                // MARK: - View Action
            case .view(.viewDidAppear):
                return .run { send in
                    await send(.checkSummary)
                }
                
            case .view(.endWorkoutButtonTapped):
                let trainingSession = state.trainingSession
                let resultInputs = state.resultInputs
                let hkWorkoutId = state.summary?.workout?.uuid
                return .run { send in
                    if let session = trainingSession, let workoutId = hkWorkoutId {
                        let score = WorkoutPlanScore(
                            trainingSessionId: session.id,
                            hkWorkoutId: workoutId,
                            results: resultInputs
                        )
                        do {
                            try await workoutPlanScoreClient.save(score)
                        } catch {
                            reportIssue(error)
                        }
                    }
                    await self.dismiss()
                }

            case let .view(.toggleResult(index)):
                guard index < state.showResults.count else { return .none }
                state.showResults[index].toggle()
                if !state.showResults[index] {
                    state.showNotes[index] = false
                    state.resultInputs[index].score = ""
                    state.resultInputs[index].note = ""
                }
                return .none

            case let .view(.toggleNote(index)):
                guard index < state.showNotes.count else { return .none }
                state.showNotes[index].toggle()
                if !state.showNotes[index] {
                    state.resultInputs[index].note = ""
                }
                return .none

            case let .view(.updateScore(index, text)):
                guard index < state.resultInputs.count else { return .none }
                state.resultInputs[index].score = text
                return .none

            case let .view(.updateNote(index, text)):
                guard index < state.resultInputs.count else { return .none }
                state.resultInputs[index].note = text
                return .none

            case .view(.viewDidDisappear):
                return .merge(
                    .cancel(id: SummaryFeatureCancelID.sessionStateListener),
                    .cancel(id: SummaryFeatureCancelID.retry)
                )
            }
        }
    }
}

/// Implementation of `SummaryFeature` action
extension SummaryFeature {
    
    @CasePathable
    enum Action: ViewAction {
        
        // MARK: - Actions
        
        /// Responsible for changing the state of the view.
        case changeViewState(SummaryState)
        
        /// Initiates the workout summary check process. If the workout is ready, transitions to a loaded state; otherwise, begins a retry sequence.
        case checkSummary

        /// Called when the workout summary has been successfully loaded.
        case summaryLoaded(WorkoutSummary)

        /// Sets the training plan associated with this session. Called by `SessionFeature` on appear.
        case setTrainingSession(TrainingSession?)
        
        // MARK: - View Actions
        
        case view(View)
        
        enum View {

            /// Action triggered when the view appears on the screen.
            case viewDidAppear

            ///
            case viewDidDisappear

            ///
            case endWorkoutButtonTapped

            /// Toggles the visibility of the entire result section for the given WOD index.
            case toggleResult(Int)

            /// Toggles the note input visibility for the given WOD index.
            case toggleNote(Int)

            /// Updates the score text for the given WOD index.
            case updateScore(Int, String)

            /// Updates the note text for the given WOD index.
            case updateNote(Int, String)
        }
    }
}

/// Implementation of `SummaryFeature` state
extension SummaryFeature {
    
    @ObservableState
    struct State {

        // MARK: - Properties

        /// Current loading/display state of the summary screen.
        var viewState: SummaryState = .loading

        /// HealthKit workout data loaded after the session ends.
        var summary: WorkoutSummary? = nil

        /// The training plan that was executed, if any.
        /// `nil` for free workouts (no plan selected).
        var trainingSession: TrainingSession? = nil

        /// Editable WOD results — one per workout in the plan.
        /// Built from `trainingSession.workouts` when the plan is set.
        var resultInputs: [WorkoutSessionResult] = []

        /// UI flags — whether the result section is expanded per WOD index.
        var showResults: [Bool] = []

        /// UI flags — whether note input is expanded per WOD index.
        var showNotes: [Bool] = []
    }
    
}

nonisolated enum SummaryFeatureCancelID: Hashable, Sendable {
    case sessionStateListener
    case retry
}
