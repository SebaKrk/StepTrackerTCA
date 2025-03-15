//
//  SummaryFeature.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 14/03/2025.
//

import Factory
import Foundation

protocol WorkoutSessionProtocol: Identifiable, Equatable {
    var id: String { get }
    var workoutType: WorkoutType { get }
    var movement: any MovementType { get }
    var value: String { get }
    var date: Date { get }
}

struct WorkoutSummary {
    let workouts: [any WorkoutSessionProtocol]
}

struct NewGroupedWorkouts: Identifiable {
    var id: WorkoutType { workoutType }
    
    let workoutType: WorkoutType
    let movements: [NewGroupedMovement]
}

struct NewGroupedMovement: Identifiable {
    var id: String { movement.title }
    
    let movement: any MovementType
    let sessions: [any WorkoutSessionProtocol]
}

protocol SummaryFeatureServices {
    func fetchWorkoutSummary() async throws -> WorkoutSummary
    func groupWorkoutsByWorkoutType(_ summary: WorkoutSummary) -> [NewGroupedWorkouts]
}


final class DefaultSummaryFeatureServices: SummaryFeatureServices {
    
    // MARK: - Dependencies
    
    @LazyInjected(\.workoutStrengthRepository) private var workoutStrengthRepository
    @LazyInjected(\.weightLiftingRepository) private var weightLiftingRepository
    
    // MARK: - API
    
    func fetchWorkoutSummary() async throws -> WorkoutSummary {
        let sessions = try await [
            workoutStrengthRepository.fetchSessions(),
            weightLiftingRepository.fetchSessions()
        ].flatMap { $0 }
        
        return WorkoutSummary(workouts: sessions)
    }
    
    func groupWorkoutsByWorkoutType(_ summary: WorkoutSummary) -> [NewGroupedWorkouts] {
        let groupedByType = groupSessionsByWorkoutType(summary)
        
        return groupedByType.map { (workoutType, sessions) in
            let groupedMovements = groupMovementsBySession(sessions)
            return NewGroupedWorkouts(workoutType: workoutType, movements: groupedMovements)
        }
    }
    
    // MARK: - Private methods
    
    private func groupSessionsByWorkoutType(_ summary: WorkoutSummary) -> [WorkoutType: [any WorkoutSessionProtocol]] {
        summary.workouts
            .reduce(into: [WorkoutType: [any WorkoutSessionProtocol]]()) { result, session in
                result[session.workoutType, default: []].append(session)
            }
    }
    
    private func groupMovementsBySession(_ sessions: [any WorkoutSessionProtocol]) -> [NewGroupedMovement] {
        let groupedMovements = sessions
            .reduce(into: [String: [any WorkoutSessionProtocol]]()) { result, session in
                let movementKey = session.movement.title
                result[movementKey, default: []].append(session)
            }
            .map { NewGroupedMovement(movement: $0.value.first!.movement, sessions: $0.value) }

        return groupedMovements
    }
    
}


import ComposableArchitecture
import Foundation

@Reducer
struct SummaryFeature {
    
    // MARK: - Dependencies
    
    let services: SummaryFeatureServices
    
    // MARK: - Livecycle
    
    init(service: SummaryFeatureServices) {
        self.services = service
    }
    
    // MARK: - Reducer
    
    var body: some Reducer<State, Action> {
        Reduce { state,action in
            switch action {
                // MARK: - Action
            case .getData:
                return .run { send in
                    do {
                        let data = try await services.fetchWorkoutSummary()
                        await send(.updateData(data))
                    } catch {
                        // TODO: - obsługa błędów
                        print("Error fetching workout strength data: \(error)")
                    }
                }
            case let .updateData(data):
                state.data = data
                state.groupedWorkouts = services.groupWorkoutsByWorkoutType(data)
                return .none
                
                // MARK: - View Action
            case .view(.viewDidAppear):
                return .run { send in
                    await send(.getData)
                }
            case let .view(.navigationButtonTapped(workoutType)):
                if let selectedWorkout = state.groupedWorkouts?.first(where: { $0.workoutType == workoutType }) {
                    state.destination = .open(ScoresFeature.State(selectedWorkout: selectedWorkout))
                } else {
                    print("No matching wxorkout found for \(workoutType.title)")
                }
                return .none
                
                // MARK: - Destination
            case .destination:
                return .none
            }
        }
        
        .ifLet(\.$destination, action: \.destination)
    }
}

import ComposableArchitecture
import Foundation

/// Defines the actions available in `SummaryFeature`, handling data fetching,
/// state updates, and user interactions.
extension SummaryFeature {
    @CasePathable
    enum Action: ViewAction {
        // MARK: - Actions
        
        /// Fetches workout data asynchronously.
        case getData
        
        ///
        case updateData(WorkoutSummary)
        
        // MARK: - View Actions
        
        /// Handles view-related actions.
        case view(View)
        
        /// Defines user interactions within the view.
        enum View {
            
            /// Triggered when the view appears.
            case viewDidAppear
            
            /// Triggered when a navigation button is tapped.
            case navigationButtonTapped(WorkoutType)
        }
        
        // MARK: - Destination
        
        /// Triggered to display a destination or handle navigation actions.
        //case show([WorkoutStrength])
        
        /// Destination case for navigation
        case destination(PresentationAction<Destination.Action>)
    }
    
}
    
    
import ComposableArchitecture
import Foundation
    
    /// Represents the state for `SummaryFeature`
extension SummaryFeature {
    
    @ObservableState
    struct State {
        
        // MARK: - Properties
        
        ///
        var data: WorkoutSummary?
        
        ///
        var groupedWorkouts: [NewGroupedWorkouts]?
        
        // MARK: - Destination
        
        /// Represents the navigation destination state within `SummaryFeature`.
        @Presents var destination: Destination.State?
    }
    
}


import ComposableArchitecture
import Foundation

/// Implementation of `SummaryFeature` destination
extension SummaryFeature {
    
    @Reducer
    enum Destination {
        
        /// Represents the destination for displaying in `ScoreFeature`.
        case open(ScoresFeature)
    }
    
}

import ComposableArchitecture
import SwiftUI

@ViewAction(for: SummaryFeature.self)
struct SummaryView: View {
    
    // MARK: - Properties
    
    @Bindable var store: StoreOf<SummaryFeature>
    // MARK: - View
    
    var body: some View {
        Group {
            summaryBody
        }
        .onAppear {
            send(.viewDidAppear)
        }
        .navigationDestination(
            item: $store.scope(
                state: \.destination?.open,
                action: \.destination.open)) { store in
                    ScoresView(store: store)
                }
        
    }
    
    // MARK: - SubView
    
    @ViewBuilder
    private var summaryBody: some View {
        if let data = store.groupedWorkouts {
            ForEach(data) { item in
                /// Nazwa kategorii treningowej (np. Weightlifting, Strength)
                summaryWorkoutTypeWidget(item)
            }
        } else {
            unavailableView
        }
    }
    
    
    private func summaryWorkoutTypeWidget(_ data: NewGroupedWorkouts) -> some View {
        GroupBox {
            VStack {
                titleContainerView
                Divider()
                Spacer().frame(height: 10)
                
                ForEach(data.movements) { movement in
                    summaryByGroupedMovement(movement)
                    Divider()
                }
                Spacer()
            }
        } label: {
            summaryTitleHeader(data.workoutType.title, data.workoutType.icon, workoutType: data.workoutType)
        }
        .frame(minHeight: 200)
    }

    private func summaryByGroupedMovement(_ data: NewGroupedMovement) -> some View {
        GeometryReader { geometry in
            HStack {
                Text(data.movement.title)
                    .font(.system(size: 14, weight: .regular, design: .monospaced))
                    .frame(width: geometry.size.width * 0.4, alignment: .leading)
                
                /// Text(summary.goal.map { "\($0) kg" } ?? "-")
                Text("_")
                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                    .frame(width: geometry.size.width * 0.3, alignment: .center)
                Spacer(minLength: 5)
                Text(data.sessions.last?.value ?? "brak")
                    .font(.system(size: 14, weight: .regular, design: .monospaced))
                    .frame(width: geometry.size.width * 0.28, alignment: .trailing)
                
            }
        }
        .frame(height: 20)
    }
    
    private func summaryTitleHeader(_ title: String, _ icon: String,
                                    workoutType: WorkoutType) -> some View {
        WidgetHeaderView(title: title, systemImage: icon, color: .green) {
            send(.navigationButtonTapped(workoutType))
        }
    }

    private var titleContainerView: some View {
        GeometryReader { geometry in
            HStack {
                titleView("Exercise")
                    .frame(width: geometry.size.width * 0.4, alignment: .leading)
                    .padding(.leading,2)
                titleView("Goal")
                    .frame(width: geometry.size.width * 0.3, alignment: .center)
                titleView("Result")
                    .frame(width: geometry.size.width * 0.3, alignment: .trailing)
                    .padding(.trailing, 5)
            }
            .frame(width: geometry.size.width)
        }
        .frame(height: 20)
    }
    
    private func titleView(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 14, weight: .bold, design: .monospaced))
    }
    
    private var unavailableView: some View {
        ChartContentUnavailable()
    }
}
