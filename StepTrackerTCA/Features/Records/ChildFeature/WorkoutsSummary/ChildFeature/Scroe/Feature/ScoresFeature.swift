//
//  ScoresFeature.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 14/03/2025.
//

protocol ScoresFeatureServices {
    func bestSession(from sessions: [any WorkoutSessionProtocol]) -> (any WorkoutSessionProtocol)?
}


final class DefaultScoresFeatureServices: ScoresFeatureServices {
    
    func bestSession(from sessions: [any WorkoutSessionProtocol]) -> (any WorkoutSessionProtocol)? {
        return sessions.max { Double($0.value) ?? 0 < Double($1.value) ?? 0 }
    }
    
}

import ComposableArchitecture
import Foundation

@Reducer
struct ScoresFeature {
    
    // MARK: - Dependencies
    
    let services: ScoresFeatureServices
    
    // MARK: - Livecycle
    
    init(service: ScoresFeatureServices = DefaultScoresFeatureServices()) {
        self.services = service
    }
    
    // MARK: - Reducer
    
    var body: some Reducer<State, Action> {
        Reduce { state,action in
            switch action {
                // MARK: - Action
                
            case .updateWorkout:
                let selectedWorkout = state.selectedWorkout
                state.bestResult = services.bestSession(from: selectedWorkout.movements.flatMap { $0.sessions })
                return .none
                
                // MARK: - View Action
            case .view(.viewDidAppear):
                return .run { send in
                    await send(.updateWorkout)
                }
            case let .view(.openExerciseInfo(movement)):
                state.destination = .openInfo(MovementInfoFeature.State(movement: movement))
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

/// Defines the actions available in `ScoresFeature`, handling data fetching,
/// state updates, and user interactions.
extension ScoresFeature {
    @CasePathable
    enum Action: ViewAction {
        // MARK: - Actions
        
        case updateWorkout
        
        // MARK: - View Actions
        
        /// Handles view-related actions.
        case view(View)
        
        /// Defines user interactions within the view.
        enum View {
            
            /// Triggered when the view appears.
            case viewDidAppear
            
            /// Opens the exercise details for a given `MovementType`.
            /// This action is triggered when the user selects a specific movement to inspect.
            ///
            /// - Parameter movement: The selected movement type.
            case openExerciseInfo(any MovementType)
            
        }
        
        // MARK: - Destination
        
        /// Destination case for navigation
        case destination(PresentationAction<Destination.Action>)
    }
    
}


import ComposableArchitecture
import Foundation

/// Represents the state for `ScoresFeature`
extension ScoresFeature {
    
    @ObservableState
    struct State {
        
        // MARK: - Properties
        
        ///
        var selectedWorkout: NewGroupedWorkouts
        
        var bestResult: (any WorkoutSessionProtocol)?
        
        
        
        // MARK: - Destination
        
        /// Represents the navigation destination state within `SummaryFeature`.
        @Presents var destination: Destination.State?
    }
    
}


import ComposableArchitecture
import Foundation

/// Implementation of `ScoresFeature` destination
extension ScoresFeature {
    
    @Reducer
    enum Destination {
        
        /// Represents the destination for displaying in `ScoresFeature`.
        //case open(ScoreFeature)
        
        /// Represents the destination for displaying in `MovementInfoFeature`.
        case openInfo(MovementInfoFeature)
    }
    
}

import ComposableArchitecture
import SwiftUI

@ViewAction(for: ScoresFeature.self)
struct ScoresView: View {
    
    // MARK: - Properties
    
    @Bindable var store: StoreOf<ScoresFeature>
    // MARK: - View
    
    var body: some View {
        ScrollView {
            scoresBody
        }
        .navigationTitle("\(store.selectedWorkout.workoutType.title) scores")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            toolbarButton
        }
        .onAppear {
            send(.viewDidAppear)
        }
        .sheet(item: $store.scope(state: \.destination?.openInfo, action: \.destination.openInfo), content: { store in
            MovementInfoView(store: store)
                .presentationDetents([.medium, .large])
        })
    }
    
    // MARK: - SubView
    
    @ToolbarContentBuilder
    var toolbarButton: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                
            } label: {
                Image(systemName: "plus")
            }
        }
    }
    
    private var scoresBody: some View {
        ForEach(store.selectedWorkout.movements, id: \.id) { movement in
            scoresMovementWidget(movement)
        }
    }
    
    private func scoresMovementWidget(_ data: NewGroupedMovement) -> some View {
        GroupBox {
            VStack {
                buildScoreStack(data)
                Spacer()
                infoButton(data.movement)
            }
            .frame(minHeight: 100)
        } label: {
            VStack {
                containerHeaderView(data)
                Divider()
            }
        }
    }
    
    private func containerHeaderView(_ data: NewGroupedMovement)  -> some View {
        HStack {
            Group {
                groupBoxHeaderTitle(data.movement.title)
                Spacer()
                containerNavigationButton()
            }
            .foregroundStyle(.green)
        }
        
    }
    
    private func groupBoxHeaderTitle(_ title: String) -> some View {
        Text(title)
            .font(.title3.bold())
    }
    
    private func containerNavigationButton() -> some View {
        Button {
            
        } label: {
            Image(systemName: "chevron.right")
        }
    }
    
    private func infoButton(_ movement: any MovementType) -> some View {
        HStack {
            Spacer()
            Button {
                send(.openExerciseInfo(movement))
            } label: {
                Image(systemName: "info.circle")
                    .foregroundStyle(.green)
            }
        }
        .padding(.top,4)
    }
    
    @ViewBuilder
    private func buildScoreStack(_ data: NewGroupedMovement) -> some View {
        VStack {
            createCellScoreView("calendar", "Last", data.sessions.last?.value, data.sessions.last?.date)
            createCellScoreView("target", "Target", nil, nil)
            createCellScoreView("trophy", "Best", store.bestResult?.value, store.bestResult?.date)
        }
    }
    
    private func createCellScoreView(_ image: String, _ title: String, _ value: String?, _ date: Date?) -> some View {
        GeometryReader { geometry in
            VStack { 
                HStack {
                    HStack {
                        Image(systemName: image)
                            .foregroundStyle(.green)
                        Text(title)
                            .font(.system(size: 14, weight: .regular, design: .monospaced))
                    }
                    .frame(width: geometry.size.width * 0.3, alignment: .leading)
                    
                    Group {
                        if let value = value {
                            Text("\(value) kg")
                                .foregroundStyle(.green)
                        } else {
                            Text("brak")
                                .foregroundStyle(.white)
                        }
                    }
                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                    .frame(width: geometry.size.width * 0.4, alignment: .center)
                    
                    Group {
                        if let date = date {
                            Text(date, format: .dateTime.day().month().year())
                        } else {
                            Text("-")
                        }
                    }
                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                    .frame(width: geometry.size.width * 0.28, alignment: .trailing)
                }
                Divider()
            }
        }
        .frame(height: 30)
    }
    
}
