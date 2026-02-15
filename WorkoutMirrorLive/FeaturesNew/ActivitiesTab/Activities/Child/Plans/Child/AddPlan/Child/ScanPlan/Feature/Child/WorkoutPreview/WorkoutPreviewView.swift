//
//  WorkoutPreviewView.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 12/02/2026.
//

import ComposableArchitecture
import SharedModels
import SwiftUI

@ViewAction(for: WorkoutPreviewFeature.self)
struct WorkoutPreviewView: View {

    // MARK: - Properties

    let store: StoreOf<WorkoutPreviewFeature>

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                headerSection

                // Warmup
                if let warmUp = store.trainingSession.warmUp {
                    sectionCard(
                        title: "Warmup",
                        icon: "figure.walk",
                        color: .orange
                    ) {
                        warmUpContent(warmUp)
                    }
                }

                // Workouts
                ForEach(Array(store.trainingSession.workouts.enumerated()), id: \.offset) { index, workout in
                    sectionCard(
                        title: workout.name,
                        icon: "figure.strengthtraining.traditional",
                        color: .blue
                    ) {
                        workoutContent(workout)
                    }
                }

                // Cooldown
                if let coolDown = store.trainingSession.coolDown {
                    sectionCard(
                        title: "Cooldown",
                        icon: "figure.cooldown",
                        color: .green
                    ) {
                        coolDownContent(coolDown)
                    }
                }
            }
            .padding()
        }
        .navigationTitle(store.trainingSession.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            toolbarContent
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundStyle(.secondary)
                Text(store.trainingSession.date, style: .date)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            HStack {
                Image(systemName: "location")
                    .foregroundStyle(.secondary)
                Text(store.trainingSession.location.title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            HStack {
                Image(systemName: "figure.cross.training")
                    .foregroundStyle(.secondary)
                Text(store.trainingSession.activity.title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    // MARK: - Section Card

    @ViewBuilder
    private func sectionCard<Content: View>(
        title: String,
        icon: String,
        color: Color,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
            }

            Divider()

            content()
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    // MARK: - Warmup Content

    private func warmUpContent(_ warmUp: WarmUpSession) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if let time = warmUp.time {
                HStack {
                    Image(systemName: "clock")
                        .foregroundStyle(.secondary)
                    Text("\(time) min")
                        .font(.subheadline)
                }
            }

            if let description = warmUp.description {
                Text(description)
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Workout Content

    private func workoutContent(_ workout: WorkoutSessionNew) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Workout metadata
            HStack {
                Label(workout.type.displayName.uppercased(), systemImage: "bolt.fill")
                    .font(.caption)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue)
                    .cornerRadius(6)

                if let timeCap = workout.timeCap {
                    Label("\(timeCap) min cap", systemImage: "timer")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let rounds = workout.rounds {
                    Label("\(rounds) rounds", systemImage: "arrow.clockwise")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Divider()

            // Exercises
            ForEach(workout.exercises) { exercise in
                exerciseRow(exercise)
            }
        }
    }

    // MARK: - Exercise Row

    private func exerciseRow(_ exercise: ExerciseSession) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "checkmark.circle")
                .foregroundStyle(.green)

            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.type.displayName)
                    .font(.body)
                    .fontWeight(.medium)

                if let target = exercise.target {
                    Text(targetDescription(target))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let sets = exercise.sets {
                    Text(setsDescription(sets))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let weight = exercise.weight {
                    Text(weightDescription(weight))
                        .font(.caption)
                        .foregroundStyle(.blue)
                }

                if let info = exercise.info {
                    Text(info)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }

    // MARK: - Cooldown Content

    private func coolDownContent(_ coolDown: CoolDownSession) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if let time = coolDown.time {
                HStack {
                    Image(systemName: "clock")
                        .foregroundStyle(.secondary)
                    Text("\(time) min")
                        .font(.subheadline)
                }
            }

            if let description = coolDown.description {
                Text(description)
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button {
                send(.editButtonTapped)
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            // ✅ Enabled - dismisses preview and goes back to idle
        }

        ToolbarItem(placement: .topBarTrailing) {
            Button {
                send(.saveButtonTapped)
            } label: {
                Label("Save", systemImage: "checkmark")
            }
            .disabled(true) // TODO: Enable in Subtask F
        }
    }

    // MARK: - Helpers

    private func targetDescription(_ target: ExerciseTarget) -> String {
        switch target {
        case .reps(let count):
            return "\(count) reps"
        case .calories(let count):
            return "\(count) cal"
        case .meters(let count):
            return "\(count) m"
        case .seconds(let count):
            return "\(count) sec"
        case .minutes(let count):
            return "\(count) min"
        case .rounds(let count):
            return "\(count) rounds"
        case .laps(let count):
            return "\(count) laps"
        }
    }

    private func weightDescription(_ weight: WeightConfiguration) -> String {
        var parts: [String] = []
        if let men = weight.men {
            parts.append("M: \(men) kg")
        }
        if let women = weight.women {
            parts.append("W: \(women) kg")
        }
        return parts.joined(separator: " / ")
    }

    private func setsDescription(_ sets: [SetScheme]) -> String {
        sets.map { set in
            var description = "\(set.count)×\(set.reps)"
            if let intensity = set.intensity {
                description += " @ \(intensity)"
            }
            return description
        }.joined(separator: ", ")
    }

}
