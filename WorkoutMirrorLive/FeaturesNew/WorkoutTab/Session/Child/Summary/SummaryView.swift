//
//  SummaryView.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 30/08/2025.
//

import ComposableArchitecture
import Commons
import HealthKit
import SwiftUI
import SharedModels

private enum FocusField: Hashable {
    case score(Int)
    case note(Int)
}

@ViewAction(for: SummaryFeature.self)
struct SummaryView: View {

    // MARK: - Properties

    @Bindable var store: StoreOf<SummaryFeature>
    @FocusState private var focusedField: FocusField?
    
    // MARK: - Body
    
    var body: some View {
        Group {
            switch store.viewState {
            case .loading:
                loadingView
            case .successfullyLoaded:
                summaryView
            case .failed:
                failedView
            }
        }
        .onAppear {
            send(.viewDidAppear)
        }
    }
    
    // MARK: - Loading
    
    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView("Saving workout")
            Spacer()
        }
        .transition(.opacity)
    }
    
    // MARK: - Failed

    private var failedView: some View {
        ContentUnavailableView(
            String(localized: "Could not load summary"),
            systemImage: "exclamationmark.triangle",
            description: Text("Something went wrong while saving your workout.")
        )
    }

    // MARK: - Summary
    
    @ViewBuilder
    private var summaryView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 12) {
                    if let workout = store.summary?.workout {
                        headerCard(workout: workout)
                        metricsGrid(workout: workout)
                    }
                    if !store.resultInputs.isEmpty {
                        wodResultsSection
                    }
                }
                .padding(.horizontal, 8)
                .padding(.top, 8)
                .contentShape(Rectangle())
                .onTapGesture { focusedField = nil }
            }
            .contentMargins(.bottom, 40, for: .scrollContent)
            .scrollDismissesKeyboard(.interactively)
            .task(id: focusedField) {
                guard let field = focusedField else { return }
                try? await Task.sleep(nanoseconds: 350_000_000)
                withAnimation(.easeInOut(duration: 0.25)) {
                    proxy.scrollTo(field, anchor: .center)
                }
            }
        }
        .background(
            LinearGradient(
                colors: [Color.gray.opacity(0.2), .clear],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
        .navigationTitle(String(localized: "Summary"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarContent }
        .alert(store: store.scope(state: \.$discardAlert, action: \.alert))
    }
    
    // MARK: - Header Card
    
    private func headerCard(workout: HKWorkout) -> some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline) {
                    Text(workout.workoutActivityType.name)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(workout.duration.formattedDuration())
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Image(systemName: workout.workoutActivityType.iconNameSimple)
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("\(workout.startDate.formatted(date: .omitted, time: .shortened)) – \(workout.endDate.formatted(date: .omitted, time: .shortened))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(workout.startDate.formatted(.dateTime.weekday(.wide)))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .styledGroupBox()
    }
    
    // MARK: - Metrics Grid
    
    private func metricsGrid(workout: HKWorkout) -> some View {
        let calories = workout.statistics(for: .init(.activeEnergyBurned))?
            .sumQuantity()
            .map { Int($0.doubleValue(for: .kilocalorie())) }
        
        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], alignment: .leading, spacing: 12) {
            metricCard(
                icon: "flame.fill",
                iconColor: .primary,
                title: "Calories Active",
                value: calories.map { "\($0)" } ?? "--",
                unit: "kcal"
            )
            metricCard(
                icon: "heart.fill",
                iconColor: .primary,
                title: "Avg HR",
                value: Int(store.summary?.metrics.averageHeartRate ?? 0).formatted(.number),
                unit: "bpm"
            )
            metricCard(
                icon: "heart.fill",
                iconColor: .primary,
                title: "Max HR",
                value: Int(store.summary?.metrics.heartRate ?? 0).formatted(.number),
                unit: "bpm"
            )
            metricCard(
                icon: "timer",
                iconColor: .primary,
                title: "Time",
                value: workout.duration.formattedDuration(),
                unit: ""
            )
        }
    }
    
    private func metricCard(icon: String, iconColor: Color, title: String, value: String, unit: String) -> some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 4) {
                    Image(systemName: icon)
                        .foregroundStyle(iconColor)
                    Text(title)
                        .font(.caption)
                        .textCase(.uppercase)
                }
                Spacer(minLength: 0)
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(value)
                        .font(.largeTitle.bold())
                        .foregroundStyle(.primary)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                    if !unit.isEmpty {
                        Text(unit)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
        .styledGroupBox()
        .frame(maxHeight: .infinity)
    }
    
    // MARK: - WOD Results Section

    private var wodResultsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Results")
                .font(.headline)
                .padding(.horizontal, 4)

            ForEach(Array(store.resultInputs.enumerated()), id: \.offset) { index, result in
                GroupBox {
                    if index < store.showResults.count && store.showResults[index] {
                        VStack(spacing: 0) {
                            if !result.description.isEmpty {
                                Divider().padding(.leading)
                                editorRow {
                                    Text(result.description)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                }
                            }

                            Divider().padding(.leading)
                            TextField("Enter score...", text: Binding(
                                get: { store.resultInputs[index].score },
                                set: { send(.updateScore(index, $0)) }
                            ), axis: .vertical)
                            .lineLimit(1...4)
                            .focused($focusedField, equals: .score(index))
                            .id(FocusField.score(index))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 10)

                            Divider().padding(.leading)
                            if index < store.showNotes.count && store.showNotes[index] {
                                TextField("Add note...", text: Binding(
                                    get: { store.resultInputs[index].note },
                                    set: { send(.updateNote(index, $0)) }
                                ), axis: .vertical)
                                .lineLimit(1...4)
                                .focused($focusedField, equals: .note(index))
                                .id(FocusField.note(index))
                                .padding(.horizontal, 4)
                                .padding(.vertical, 10)
                            } else {
                                editorRow {
                                    Text("Note")
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    Button {
                                        send(.toggleNote(index))
                                    } label: {
                                        Image(systemName: "plus.circle")
                                            .font(.title3)
                                            .foregroundStyle(.secondary)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                } label: {
                    VStack(spacing: 4) {
                        HStack {
                            Text(result.name)
                                .font(.subheadline)
                                .bold()
                            Spacer()
                            Toggle("", isOn: Binding(
                                get: { index < store.showResults.count && store.showResults[index] },
                                set: { _ in send(.toggleResult(index)) }
                            ))
                            .labelsHidden()
                        }
                        Divider()
                    }
                }
                .styledGroupBox()
            }
        }
    }

    // MARK: - Helpers

    @ViewBuilder
    private func editorRow<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        HStack { content() }
            .padding(.vertical, 10)
            .padding(.horizontal, 4)
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .bottomBar) {
            Button {
                send(.discardWorkoutButtonTapped)
            } label: {
                Text("Odrzuć")
                    .foregroundStyle(.red)
            }
            Spacer()
            Button {
                send(.endWorkoutButtonTapped)
            } label: {
                Text("Zapisz")
                    .fontWeight(.semibold)
            }
        }
    }
}

// MARK: - Helpers

extension TimeInterval {
    func formattedDuration() -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: self) ?? "--"
    }
}

// MARK: - Preview

#Preview("failed") {
    SummaryView(store: Store(initialState: SummaryFeature.State(viewState: .failed)) {
        SummaryFeature()
    } withDependencies: {
        $0.sessionClient.getWorkoutSummary = {
            await withCheckedContinuation { (_: CheckedContinuation<WorkoutSummary, Never>) in }
        }
    })
}

#Preview("loading") {
    SummaryView(store: Store(initialState: SummaryFeature.State(), reducer: {
        SummaryFeature()
    }))
}

#Preview("loaded — short") {
    let summary = WorkoutSummary.previewWorkoutSummary()
    var state = SummaryFeature.State(viewState: .successfullyLoaded)
    state.summary = summary
    return NavigationStack {
        SummaryView(store: Store(initialState: state) {
            SummaryFeature()
        } withDependencies: {
            $0.sessionClient.getWorkoutSummary = { summary }
        })
    }
}

#Preview("loaded — long (2h+)") {
    let end = Date()
    let start = end.addingTimeInterval(-7890) // 2h 11m 30s
    let workout = HKWorkout(activityType: .crossTraining, start: start, end: end)
    let summary = WorkoutSummary(
        workout: workout,
        metrics: WorkoutMetrics(averageHeartRate: 155, heartRate: 178, activeEnergy: 1240)
    )
    var state = SummaryFeature.State(viewState: .successfullyLoaded)
    state.summary = summary
    return NavigationStack {
        SummaryView(store: Store(initialState: state) {
            SummaryFeature()
        } withDependencies: {
            $0.sessionClient.getWorkoutSummary = { summary }
        })
    }
}
