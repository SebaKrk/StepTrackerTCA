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
        .navigationTitle("\(store.selectedWorkoutType.rawValue) scores")
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
            WorkoutSubmissionView(store: store)
        })
        .sheet(item: $store.scope(state: \.destination?.openSubmitWorkout, action: \.destination.openSubmitWorkout), content: { store in
            WorkoutSubmissionView(store: store)
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
                send(.submitWorkoutScoreButtonTapped)
            } label: {
                Image("custom.figure.run.circle.badge.plus")
            }
        }
        
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                send(.goalsButtonTapped)
            } label: {
                Image("custom.target.badge.plus")
            }
        }
    }
    
    @ViewBuilder
    private var scoresBody: some View {
        ForEach(store.filteredMovements) { filteredMovement in
            scoresMovementWidget(filteredMovement)
        }
    }
    
    private func scoresMovementWidget(_ data: ScoresFeature.FilteredMovement) -> some View {
        GroupBox {
            VStack {
                buildScoreStack(data)
                Spacer()
                infoButton(data.movement)
            }
            .frame(minHeight: 100)
        } label: {
            VStack {
                containerHeaderView(data.movement)
                Divider()
            }
        }
    }
    
    private func containerHeaderView(_ movement: String)  -> some View {
        HStack {
            Group {
                groupBoxHeaderTitle(movement)
                Spacer()
                containerNavigationButton(movement)
            }
            .foregroundStyle(.green)
        }
    }
    
    private func groupBoxHeaderTitle(_ title: String) -> some View {
        Text(title)
            .font(.title3.bold())
    }

    private func containerNavigationButton(_ movement: String) -> some View {
        Button {
            send(.openMovementDetails(movement))
        } label: {
            Image(systemName: "chevron.right")
        }
    }
    
    private func infoButton(_ movement: String) -> some View {
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
    private func buildScoreStack(_ data: ScoresFeature.FilteredMovement) -> some View {
        VStack(spacing: 8) {
            ForEach(buildScoreItems(from: data), id: \.title) { item in
                createCellScoreView(item.icon, item.title, item.value, item.date, workoutType: data.best!.workoutType)
            }
        }
    }

    private func buildScoreItems(from data: ScoresFeature.FilteredMovement) -> [ScoreItem] {
        [
            ScoreItem(icon: "calendar", title: "Last", value: data.last?.value, date: data.last?.date),
            ScoreItem(icon: "target", title: "Target", value: data.goal?.value, date: data.goal?.date),
            ScoreItem(icon: "trophy", title: "Best", value: data.best?.value, date: data.best?.date)
        ]
    }
    
    private func createCellScoreView(
        _ image: String,
        _ title: String,
        _ value: Double?,
        _ date: Date?,
        workoutType: WorkoutType
    ) -> some View {
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
                            Text(formatValue(value, for: workoutType))
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

    private func formatValue(_ value: Double, for workoutType: WorkoutType) -> String {
        switch workoutType {
        case .weightlifting, .strength:
            return String(format: "%.2f kg", value)
            
        case .hero, .fitness:
            let timeInterval = value
            let formatter = DateComponentsFormatter()
            formatter.allowedUnits = timeInterval >= 3600 ? [.hour, .minute, .second] : [.minute, .second]
            formatter.unitsStyle = .positional
            formatter.zeroFormattingBehavior = .pad
            return formatter.string(from: timeInterval) ?? "Invalid Time"
            
        case .cross:
            return String(format: "%.0f reps", value)
        }
    }
    
    /// A structure used specifically for the `ScoresView`.
    /// Represents a single score item containing relevant details for display.
    struct ScoreItem {
        /// The icon name representing the score item (e.g., "calendar", "target", "trophy").
        let icon: String
        
        /// The title describing the score item (e.g., "Last", "Target", "Best").
        let title: String
        
        /// The value associated with the score item, if available.
        let value: Double?
        
        /// The date associated with the score item, if available.
        let date: Date?
    }
    
}
