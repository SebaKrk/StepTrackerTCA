//
//  WorkoutDetailContent.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 12/02/2026.
//
//  Shared workout detail UI used by both WorkoutPreviewView and PlanDetailView.

import SharedModels
import SwiftUI

/// Displays a full TrainingSession — summary card, warmup, WODs, cooldown.
///
/// Both WorkoutPreviewView (scan flow) and PlanDetailView (plans list) use this
/// component. The warmup/cooldown sections are collapsible via bindings.
struct WorkoutDetailContent: View {

    let session: TrainingSession
    let isWarmupExpanded: Binding<Bool>
    let isCooldownExpanded: Binding<Bool>

    var body: some View {
        VStack(spacing: 12) {
            summaryCard

            if let warmUp = session.warmUp {
                warmupCard(warmUp)
            }

            ForEach(session.workouts) { workout in
                wodCard(workout)
            }

            if let coolDown = session.coolDown {
                cooldownCard(coolDown)
            }
        }
    }

    // MARK: - Summary Card

    private var summaryCard: some View {
        GroupBox {
            VStack(spacing: 12) {
                HStack(spacing: 0) {
                    statColumn(title: "Duration", value: formatDuration(), alignment: .leading)
                        .frame(maxWidth: 110)
                    statColumn(title: "Location", value: session.location.title)
                        .frame(maxWidth: 90)
                    statColumn(title: "Type", value: formatTypes(), isLast: true)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(4)
        } label: {
            VStack {
                sessionHeader
                Divider()
            }
        }
        .styledGroupBox()
    }

    private var sessionHeader: some View {
        HStack {
            Image(systemName: session.activity.iconName.replacingOccurrences(of: ".circle.fill", with: ""))
                .resizable()
                .scaledToFit()
                .foregroundColor(.primary)
                .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(session.title)
                    .foregroundColor(.primary)
                    .font(.title2)
                    .bold()
                Text(session.date, style: .date)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }

    // MARK: - Warmup Card

    private func warmupCard(_ warmUp: WarmUpSession) -> some View {
        GroupBox {
            DisclosureGroup(isExpanded: isWarmupExpanded) {
                VStack(alignment: .leading, spacing: 8) {
                    if !warmUp.description.isEmpty {
                        Text(warmUp.description)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 4)
            } label: {
                HStack {
                    Text("Warmup")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Spacer()
                    if let time = warmUp.time {
                        Text("\(time) min")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .styledGroupBox()
    }

    // MARK: - WOD Card

    private func wodCard(_ workout: WorkoutSessionNew) -> some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Text(workout.type.displayName.uppercased())
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(workout.type.color.opacity(0.8))
                        .cornerRadius(6)

                    if let timeCap = workout.timeCap {
                        Text("\(timeCap) min")
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

                ForEach(workout.exercises) { exercise in
                    exerciseRow(exercise)
                }
            }
            .padding(4)
        } label: {
            VStack {
                Text(workout.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Divider()
            }
        }
        .styledGroupBox()
    }

    // MARK: - Exercise Row

    private func exerciseRow(_ exercise: ExerciseSession) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(Color.blue.opacity(0.3))
                .frame(width: 8, height: 8)
                .padding(.top, 6)

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(exercise.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)

                    Spacer()

                    if let target = exercise.target {
                        let (value, unit) = targetParts(target)
                        HStack(spacing: 2) {
                            Text(value)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                            Text(unit)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                if let weight = exercise.weight {
                    Text(weightDescription(weight))
                        .font(.caption)
                        .foregroundStyle(.blue)
                }

                if let sets = exercise.plannedSets, !sets.isEmpty {
                    plannedSetsList(sets)
                }

                if let note = exerciseNote(exercise) {
                    Text(note)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Planned Sets

    private func plannedSetsList(_ sets: [PlannedSet]) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            ForEach(Array(sets.enumerated()), id: \.offset) { index, set in
                plannedSetRow(number: index + 1, set: set)
            }
        }
        .padding(.top, 1)
    }

    private func plannedSetRow(number: Int, set: PlannedSet) -> some View {
        HStack(spacing: 6) {
            Text(setLabel(number))
                .foregroundStyle(.secondary)
            Spacer(minLength: 8)
            Text(setValue(set))
                .foregroundColor(.primary)
        }
        .font(.caption)
        .monospacedDigit()
    }

    private func setLabel(_ number: Int) -> String {
        String(localized: "Seria \(number)")
    }

    private func setValue(_ set: PlannedSet) -> String {
        guard let kg = set.suggestedWeight else { return "\(set.reps)" }
        return "\(set.reps) × \(kg.formatted(.number.precision(.fractionLength(0...1)))) kg"
    }

    // The set scheme ("3×15") is the first line of `info` (guaranteed by the
    // mapper whenever plannedSets exists) and is shown as explicit rows above,
    // so only the remaining note (cue/scaling) renders here.
    private func exerciseNote(_ exercise: ExerciseSession) -> String? {
        guard let info = exercise.info else { return nil }
        guard let sets = exercise.plannedSets, !sets.isEmpty else { return info }
        let remainder = info
            .split(separator: "\n", omittingEmptySubsequences: false)
            .dropFirst()
            .joined(separator: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return remainder.isEmpty ? nil : remainder
    }

    // MARK: - Cooldown Card

    private func cooldownCard(_ coolDown: CoolDownSession) -> some View {
        GroupBox {
            DisclosureGroup(isExpanded: isCooldownExpanded) {
                VStack(alignment: .leading, spacing: 8) {
                    if !coolDown.description.isEmpty {
                        Text(coolDown.description)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 4)
            } label: {
                HStack {
                    Text("Cooldown")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Spacer()
                    if let time = coolDown.time {
                        Text("\(time) min")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .styledGroupBox()
    }

    // MARK: - Stat Column

    private func statColumn(
        title: String,
        value: String,
        alignment: HorizontalAlignment = .center,
        isLast: Bool = false
    ) -> some View {
        HStack(spacing: 0) {
            VStack(alignment: alignment, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .bold()
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: Alignment(horizontal: alignment, vertical: .center))

            if !isLast {
                Divider()
                    .frame(height: 36)
            }
        }
    }

    // MARK: - Helpers

    private func formatDuration() -> String {
        let total = (session.warmUp?.time ?? 0)
            + session.workouts.compactMap { $0.timeCap }.reduce(0, +)
            + (session.coolDown?.time ?? 0)
        return total > 0 ? "~\(total) min" : "–"
    }

    private func formatTypes() -> String {
        let types = Array(Set(session.workouts.map { $0.type.displayName }))
        return types.isEmpty ? "–" : types.joined(separator: " · ")
    }

    private func targetParts(_ target: ExerciseTarget) -> (value: String, unit: String) {
        switch target {
        case .reps(let n):     return ("\(n)", "reps")
        case .calories(let n): return ("\(n)", "cal")
        case .meters(let n):   return ("\(n)", "m")
        case .seconds(let n):  return ("\(n)", "sec")
        case .minutes(let n):  return ("\(n)", "min")
        case .rounds(let n):   return ("\(n)", "rounds")
        case .laps(let n):     return ("\(n)", "laps")
        }
    }

    private func weightDescription(_ weight: WeightConfiguration) -> String {
        var parts: [String] = []
        if let men = weight.men { parts.append("M: \(men) kg") }
        if let women = weight.women { parts.append("W: \(women) kg") }
        return parts.joined(separator: " / ")
    }

}
