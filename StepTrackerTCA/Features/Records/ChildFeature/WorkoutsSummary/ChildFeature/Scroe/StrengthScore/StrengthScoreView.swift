//
//  StrengthScoreView.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 09/03/2025.
//

import ComposableArchitecture
import SwiftUI

@ViewAction(for: StrengthScoreFeature.self)
struct StrengthScoreView: View {
    // MARK: - Properties
    
    @Bindable var store: StoreOf<StrengthScoreFeature>
    
    // MARK: - View
    
    var body: some View {
        ScrollView {
            createScoresContainers()
        }
        .navigationTitle("StrengthScore Score")
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
                
            } label: {
                Image(systemName: "plus")
            }
        }
    }
    
    @ViewBuilder
    private func createScoresContainers() -> some View {
        if let groupedData = store.groupedWorkoutsData {
            ForEach(groupedData) { group in
                groupBoxContainer(data: group, bestWorkout: group.bestWorkout)
            }
         } else {
            Text("Brak danych")
        }
    }
    
    private func groupBoxContainer(data: GroupedWorkouts, bestWorkout: WorkoutStrength) -> some View {
        GroupBox {
            VStack {
                buildScoreStack(lastScore: data, goalTarget: nil, bestScore: bestWorkout)
                Spacer()
                infoButton(data.movement)
            }
            .frame(minHeight: 150)
        } label: {
            containerHeaderView(data.movement.rawValue,
                                movement: data.movement,
                                workoutsData: data.workouts)
            
        }
    }
    
    private func containerHeaderView(_ title: String,
                                     movement: any MovementType,
                                     workoutsData: [WorkoutStrength]) -> some View {
        VStack {
            HStack {
                Group {
                    groupBoxHeaderTitle(title)
                    Spacer()
                    containerNavigationButton(for: movement, workoutsData: workoutsData)
                }
                .foregroundStyle(.green)
            }
        }
    }
    
    private func groupBoxHeaderTitle(_ title: String) -> some View {
        Text(title)
            .font(.title3.bold())
    }
    
    private func containerNavigationButton(for movement: any MovementType, workoutsData: [WorkoutStrength]) -> some View {
        Button {
            send(.navigationButtonTapped(movement, workoutsData: workoutsData))
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
    private func buildScoreStack(lastScore: GroupedWorkouts?, goalTarget: WorkoutStrength?, bestScore: WorkoutStrength?) -> some View {
        VStack {
            createCellScoreView("calendar", "Last", lastScore?.workouts.last?.value, lastScore?.workouts.last?.date)
            createCellScoreView("target", "Target", goalTarget?.value, goalTarget?.date)
            createCellScoreView("trophy", "Best", bestScore?.value, bestScore?.date)
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
    }
    
}
