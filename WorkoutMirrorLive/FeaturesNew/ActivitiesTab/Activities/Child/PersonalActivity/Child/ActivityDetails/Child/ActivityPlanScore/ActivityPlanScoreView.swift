//
//  ActivityPlanScoreView.swift
//  WorkoutMirrorLive
//

import Commons
import ComposableArchitecture
import SharedModels
import SwiftUI

/// Plan results on the Activity Details screen. Rendered with the same
/// read-only ResultCards as the workout Summary; editing (within the edit
/// window) goes through the Summary manual-entry flow via the parent.
struct ActivityPlanScoreView: View {

    // MARK: - Properties

    @Bindable var store: StoreOf<ActivityPlanScoreFeature>

    // MARK: - Body

    var body: some View {
        switch store.loadState {
        case .loading:
            loadingView
        case let .loaded(score):
            resultsView(score)
        case .notFound, .failed:
            EmptyView()
        }
    }

    // MARK: - Structure

    private var loadingView: some View {
        GroupBox {
            loadingRow
        } label: {
            resultsLabel
        }
        .styledGroupBox()
    }

    @ViewBuilder
    private func resultsView(_ score: WorkoutPlanScore) -> some View {
        if score.results.isEmpty {
            GroupBox {
                pendingResultsHint
            } label: {
                resultsLabel
            }
            .styledGroupBox()
        } else {
            VStack(alignment: .leading, spacing: 12) {
                resultCards
                if isAnyWodEditable {
                    editFooter
                }
            }
        }
    }

    private var resultCards: some View {
        WorkoutResultsView(
            store: store.scope(state: \.resultCards, action: \.resultCards),
            accent: SummaryTheme.mint
        )
        // Native card skin here — the result cards must match the surrounding
        // Activity Details cards (HR Recovery etc.), not the dark Summary skin.
        .environment(\.summaryPalette, .native)
    }

    private var editFooter: some View {
        HStack(spacing: 8) {
            Spacer()
            editResultsButton
            editDeadlineMenu
        }
    }

    // MARK: - Implementation

    private var loadingRow: some View {
        HStack {
            Text(String(localized: "Score:", bundle: .main))
                .font(.subheadline)
                .foregroundStyle(.primary)
            Spacer()
            ProgressView()
        }
    }

    /// Plan auto-linked (IOS-00098-C) but no results yet — the whole container is
    /// the fill-in entry point; delegates up to the parent, which owns the
    /// manual-entry navigation.
    private var pendingResultsHint: some View {
        Button {
            store.send(.fillResultsTapped)
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "square.and.pencil")
                    .foregroundStyle(.orange)
                pendingResultsText
                Spacer(minLength: 8)
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 11)
            .background(.orange.opacity(0.16), in: RoundedRectangle(cornerRadius: 11, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var pendingResultsText: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(String(localized: "Fill in results"))
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.orange)
            Text(String(localized: "Plan attached — tap to add"))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .lineLimit(1)
    }

    private var editResultsButton: some View {
        Button {
            store.send(.fillResultsTapped)
        } label: {
            Label(String(localized: "Edit results"), systemImage: "pencil")
                .font(.caption)
                .fontWeight(.medium)
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
    }

    /// Tap-to-reveal info popup showing the edit deadline as a single short line.
    private var editDeadlineMenu: some View {
        Menu {
            Text(editDeadlineMessage)
        } label: {
            Image(systemName: "info.circle")
                .font(.caption)
                .fontWeight(.medium)
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
    }

    private var resultsLabel: some View {
        Label(String(localized: "Results", bundle: .main), systemImage: "list.bullet.clipboard")
            .font(.caption)
            .foregroundStyle(.secondary)
    }

    private var editDeadlineMessage: String {
        guard let deadline = store.exerciseLogs.compactMap(\.editableUntil).min() else {
            return String(localized: "Editing locked")
        }
        return String(localized: "Editable until \(DateTimeFormatter.numericDateTime.string(from: deadline))")
    }

    /// Whether any ExerciseLog of this workout is still inside its edit window.
    private var isAnyWodEditable: Bool {
        store.exerciseLogs.contains { $0.isEditable(now: Date()) }
    }

}

// MARK: - Preview

#Preview("loading") {
    let store = Store(
        initialState: ActivityPlanScoreFeature.State(hkWorkoutId: UUID())
    ) {
        ActivityPlanScoreFeature()
    } withDependencies: {
        $0.workoutPlanScoreClient.fetchByHKWorkoutId = { _ in
            await withCheckedContinuation { (_: CheckedContinuation<WorkoutPlanScore?, Never>) in }
        }
    }
    ActivityPlanScoreView(store: store)
        .onAppear { store.send(.fetchScore) }
        .padding()
}

#Preview("loaded — karty read-only") {
    let score = WorkoutPlanScore(
        trainingSessionId: UUID(),
        hkWorkoutId: UUID(),
        results: [
            WorkoutSessionResult(
                name: "WOD 1",
                description: "21-15-9 Thrusters 43kg + Pull-ups",
                scoreResult: .forTime(time: 872),
                exercises: [
                    ExerciseLogInput(exerciseType: .thrusters, category: .olympicLifting, plannedReps: "21-15-9", plannedWeight: 43, actualWeight: 43),
                    ExerciseLogInput(exerciseType: .pullUps, category: .gymnastics, plannedReps: "21-15-9", actualReps: "21-15-9"),
                ]
            ),
            WorkoutSessionResult(
                name: "Strength",
                description: "5x5 Back Squat",
                scoreResult: .forLoad(weight: 80),
                note: "Felt strong today",
                exercises: [
                    ExerciseLogInput(
                        exerciseType: .backSquat,
                        category: .strength,
                        plannedReps: "5-5-5",
                        sets: [
                            SetEntry(reps: 5, weight: 70),
                            SetEntry(reps: 5, weight: 75),
                            SetEntry(reps: 5, weight: 80),
                        ]
                    ),
                ]
            ),
        ]
    )
    let store = Store(
        initialState: ActivityPlanScoreFeature.State(hkWorkoutId: score.hkWorkoutId)
    ) {
        ActivityPlanScoreFeature()
    } withDependencies: {
        $0.workoutPlanScoreClient.fetchByHKWorkoutId = { _ in score }
    }
    ScrollView {
        ActivityPlanScoreView(store: store)
            .onAppear { store.send(.fetchScore) }
            .padding()
    }
    .background(SummaryTheme.background)
}

#Preview("notFound") {
    let store = Store(
        initialState: ActivityPlanScoreFeature.State(hkWorkoutId: UUID())
    ) {
        ActivityPlanScoreFeature()
    } withDependencies: {
        $0.workoutPlanScoreClient.fetchByHKWorkoutId = { _ in nil }
    }
    ActivityPlanScoreView(store: store)
        .onAppear { store.send(.fetchScore) }
        .padding()
}
