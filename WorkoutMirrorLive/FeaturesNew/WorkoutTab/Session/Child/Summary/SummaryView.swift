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

@ViewAction(for: SummaryFeature.self)
struct SummaryView: View {

    // MARK: - Properties

    @Bindable var store: StoreOf<SummaryFeature>

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

    // MARK: - Loading States

    // `loadingView` / `failedView` wydzielone do `SummaryView+LoadingStates.swift`

    // MARK: - Structure

    @ViewBuilder
    private var summaryView: some View {
        summaryContent
            .overlay(alignment: .bottom) { saveWorkoutBar }
            .animation(.easeInOut(duration: 0.25), value: store.isSaveButtonVisible)
            .background(summaryBackground)
            // Summary skin is one dark theme by design (mockup identity).
            .preferredColorScheme(.dark)
            .navigationTitle(summaryTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackgroundVisibility(.hidden, for: .navigationBar)
            .toolbar { toolbarContent }
            .alert(store: store.scope(state: \.$discardAlert, action: \.alert))
            .alert(store: store.scope(state: \.$errorAlert, action: \.errorAlert))
            // Block all interactions (Save/End, edit fields, toolbar) during the
            // ~delete operation. Alerts remain interactive (presented above this layer).
            .disabled(store.isDiscarding)
    }

    private var summaryContent: some View {
        ScrollView {
            VStack(spacing: 12) {
                if let workout = store.summary?.workout {
                    heroCard(workout: workout)
                    metricsGrid(workout: workout)
                }
                heartRateZonesCard
                hrMinuteChartCard
                if !store.results.cards.isEmpty {
                    workoutResultsSection
                }
                saveSentinel
            }
            .padding(.horizontal, contentHorizontalPadding)
            .padding(.top, contentTopPadding)
        }
        .scrollDismissesKeyboard(.interactively)
        // Tap anywhere that isn't a text field to dismiss the keyboard (numeric
        // pads have no Return key). Controls and field-to-field focus keep working.
        .dismissesKeyboardOnBackgroundTap()
    }

    /// Invisible bottom marker — the floating save bar reveals once it scrolls
    /// into view, and its height reserves the space the bar floats over.
    private var saveSentinel: some View {
        Color.clear
            .frame(height: 64)
            .onScrollVisibilityChange(threshold: 0.1) { isVisible in
                send(.saveButtonVisibilityChanged(isVisible))
            }
    }

    private func heroCard(workout: HKWorkout) -> some View {
        HeroCard(
            iconSystemName: workout.workoutActivityType.iconNameSimple,
            name: workout.workoutActivityType.name,
            meta: heroMeta(workout: workout),
            durationText: heroDuration(workout: workout),
            dominantZone: store.dominantZone,
            accent: accent
        )
    }

    // Duration already lives in the hero, so the grid never repeats it — the
    // fourth slot is always Effort Points (0 when none were earned, — when
    // unavailable in manual entry).
    private func metricsGrid(workout: HKWorkout) -> some View {
        LazyVGrid(columns: twoColumnGrid, alignment: .leading, spacing: 12) {
            caloriesTile(workout: workout)
            effortPointsTile
            avgHRTile
            maxHRTile
        }
    }

    @ViewBuilder
    private var heartRateZonesCard: some View {
        if !store.secondsByZone.isEmpty {
            HeartRateZonesSection(
                zoneDistribution: store.secondsByZone,
                dominantZone: store.dominantZone
            )
            .summaryCard()
        }
    }

    @ViewBuilder
    private var hrMinuteChartCard: some View {
        if !store.hrMinuteRanges.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                hrChartHeader
                HRMinuteRangeChart(
                    ranges: store.hrMinuteRanges,
                    userMaxHeartRate: Int(store.userMaxHeartRate ?? 0),
                    selectedMinute: chartSelectionBinding
                )
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .summaryCard()
        }
    }

    private var workoutResultsSection: some View {
        WorkoutResultsView(
            store: store.scope(state: \.results, action: \.results),
            accent: accent
        )
    }

    // MARK: - Implementation

    private var summaryTitle: String {
        String(localized: "Summary")
    }

    /// Dominant-zone color; mint fallback (never .accentColor — white in dark mode).
    private var accent: Color {
        store.dominantZone?.color ?? SummaryTheme.mint
    }

    private var summaryBackground: some View {
        ZStack {
            SummaryTheme.background
            // Even zone-colored wash — uniform so every card, top or bottom,
            // sits on the same surround (no screen region is favored).
            accent.opacity(0.07)
        }
        .ignoresSafeArea()
        .animation(.easeInOut, value: store.dominantZone)
    }

    private func heroMeta(workout: HKWorkout) -> String {
        let weekday = workout.startDate.formatted(.dateTime.weekday(.wide))
        let start = workout.startDate.formatted(date: .omitted, time: .shortened)
        let end = workout.endDate.formatted(date: .omitted, time: .shortened)
        return "\(weekday) · \(start) – \(end)"
    }

    private func heroDuration(workout: HKWorkout) -> String {
        let total = Int(workout.duration.rounded())
        return String(format: "%d:%02d", total / 60, total % 60)
    }

    private var twoColumnGrid: [GridItem] {
        [GridItem(.flexible()), GridItem(.flexible())]
    }

    private func caloriesTile(workout: HKWorkout) -> some View {
        let hkCalories = workout.statistics(for: .init(.activeEnergyBurned))?
            .sumQuantity()
            .map { Int($0.doubleValue(for: .kilocalorie())) }
        let metricsEnergy = store.summary?.metrics.activeEnergy ?? 0
        let calories: Int? = hkCalories ?? (metricsEnergy > 0 ? Int(metricsEnergy) : nil)

        return MetricTile(
            iconSystemName: "flame.fill",
            iconColor: .orange,
            title: String(localized: "Calories Active"),
            value: calories.map { "\($0)" } ?? "--",
            unit: "kcal"
        )
    }

    /// Effort points earned (Myzone-style). "—" when unavailable (old manual
    /// entry); "0" is honest for a short/low-intensity session. Mint = identity spot.
    private var effortPointsTile: some View {
        MetricTile(
            iconSystemName: "bolt.fill",
            iconColor: .yellow,
            title: String(localized: "Effort Points"),
            value: store.effortPoints.map { "\($0)" } ?? "—",
            unit: String(localized: "pts")
        )
    }

    private var avgHRTile: some View {
        MetricTile(
            iconSystemName: "heart.fill",
            iconColor: heartPink,
            title: String(localized: "Avg HR"),
            value: Int(store.summary?.metrics.averageHeartRate ?? 0).formatted(.number),
            unit: "bpm"
        )
    }

    private var maxHRTile: some View {
        MetricTile(
            iconSystemName: "waveform.path.ecg",
            iconColor: .red,
            title: String(localized: "Max HR"),
            value: store.maxHeartRate.formatted(.number),
            unit: "bpm"
        )
    }

    /// Mockup pink #FF6482.
    private var heartPink: Color {
        Color(red: 255 / 255, green: 100 / 255, blue: 130 / 255)
    }

    private var hrChartHeader: some View {
        HStack(alignment: .firstTextBaseline) {
            hrChartTitle
            Spacer()
            hrChartUnitLabel
        }
    }

    private var hrChartTitle: some View {
        Text(String(localized: "Heart rate minute by minute"))
            .font(.system(size: 14, weight: .bold))
            .foregroundStyle(SummaryTheme.ink)
    }

    private var hrChartUnitLabel: some View {
        Text("bpm")
            .font(.system(size: 12))
            .foregroundStyle(SummaryTheme.inkSecondary)
    }

    private var chartSelectionBinding: Binding<Date?> {
        Binding(
            get: { store.selectedChartMinute },
            set: { send(.chartMinuteSelected($0)) }
        )
    }

    /// Floating save bar that reveals once the user scrolls to the bottom.
    @ViewBuilder
    private var saveWorkoutBar: some View {
        if store.isSaveButtonVisible {
            SaveWorkoutButton(
                title: String(localized: "Save workout"),
                isEnabled: !store.isDiscarding
            ) {
                send(.endWorkoutButtonTapped)
            }
            .padding(.horizontal, saveButtonHorizontalPadding)
            .padding(.bottom, saveButtonBottomPadding)
            .background(saveBarScrim)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    /// Content fades under the floating bar instead of a hard edge.
    private var saveBarScrim: some View {
        LinearGradient(
            colors: [.clear, SummaryTheme.background.opacity(0.92), SummaryTheme.background],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea(edges: .bottom)
    }

    private var contentHorizontalPadding: CGFloat { 8 }

    /// Save button sits narrower than the content and clear of the bottom
    /// edge — it should read as a floating action, not a screen-wide footer.
    private var saveButtonHorizontalPadding: CGFloat { 24 }
    private var saveButtonBottomPadding: CGFloat { 24 }
    private var contentTopPadding: CGFloat { 8 }

    // MARK: - Toolbar

    // `toolbarContent` + buttons (cancel/discard) wydzielone do `SummaryView+Toolbar.swift`
}
