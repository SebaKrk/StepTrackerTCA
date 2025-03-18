//
//  ScoresView.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 15/03/2025.
//

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
        .sheet(item: $store.scope(state: \.destination?.openGoal, action: \.destination.openGoal), content: { store in
            SetEditGoalView(store: store)
        })
        .navigationDestination(
            item: $store.scope(
                state: \.destination?.showDetails,
                action: \.destination.showDetails)) { store in
                    MovementDetailsView(store: store)
                }
    }
    
    // MARK: - SubView
    
    @ToolbarContentBuilder
    var toolbarButton: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                send(.goalsButtonTapped)
            } label: {
                Image("custom.target.badge.plus")
            }
        }
    }
    
    private var scoresBody: some View {
        ForEach(store.selectedWorkout.movements, id: \.id) { movement in
            scoresMovementWidget(movement)
        }
    }
    
    private func scoresMovementWidget(_ data: GroupedMovement) -> some View {
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
    
    private func containerHeaderView(_ data: GroupedMovement)  -> some View {
        HStack {
            Group {
                groupBoxHeaderTitle(data.movement.title)
                Spacer()
                containerNavigationButton(data.movement, data.sessions)
            }
            .foregroundStyle(.green)
        }
        
    }
    
    private func groupBoxHeaderTitle(_ title: String) -> some View {
        Text(title)
            .font(.title3.bold())
    }
    
    private func containerNavigationButton(_ movement: any MovementType, _ sessions: [any WorkoutSession]) -> some View {
        Button {
            send(.openMovementDetails(movement, sessions))
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
    private func buildScoreStack(_ data: GroupedMovement) -> some View {
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
