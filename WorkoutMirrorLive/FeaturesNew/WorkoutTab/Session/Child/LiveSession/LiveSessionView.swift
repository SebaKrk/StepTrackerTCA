//
//  LiveSessionView.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 27/08/2025.
//

import ComposableArchitecture
import Commons
import SwiftUI
import SharedModels

@ViewAction(for: LiveSessionFeature.self)

struct LiveSessionView: View {

    // MARK: - Properties
    @Bindable var store: StoreOf<LiveSessionFeature>
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    private var isLandscape: Bool { verticalSizeClass == .compact }

    // MARK: - Body

    var body: some View {
        Group {
            if isLandscape {
                landscapeBody
            } else {
                portraitBody
            }
        }
        .background(
            LinearGradient(
                stops: [
                    .init(color: store.currentHeartRateZone.color.opacity(0.85), location: 0),
                    .init(color: store.currentHeartRateZone.color.opacity(0.6), location: 0.15),
                    .init(color: .clear, location: 0.8)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .background(Color.black.ignoresSafeArea())
        .preferredColorScheme(.dark)
        .modifier(StaleDesaturation(isStale: store.isSensorStale))
        .animation(.easeInOut, value: store.currentHeartRateZone)
        .animation(.easeInOut(duration: 0.25), value: store.isSensorStale)
        .onAppear { send(.viewDidAppear) }
        .onDisappear { send(.viewDidDisappear) }
    }

    // MARK: - Portrait

    private var portraitBody: some View {
        ScrollView {
            HStack {
                secondaryMetricCard("avg hr",
                                    data: store.sessionAverageHeartRate)
                secondaryMetricCard("max hr",
                                    data: store.sessionMaxHeartRate)
            }
            workoutMetricsCard

            if store.userStopwatch.isVisible {
                StopwatchView(store: store.scope(state: \.userStopwatch, action: \.userStopwatch))
            } else {
                switch store.selectedWorkout {
                case .cycling:
                    CyclingTileView(
                        metrics: store.workoutMetrics,
                        currentPage: $store.distanceTilePage.sending(\.view.distanceTilePageChanged)
                    )
                case .running:
                    RunningTileView(
                        metrics: store.workoutMetrics,
                        currentPage: $store.distanceTilePage.sending(\.view.distanceTilePageChanged)
                    )
                case .indoorRunning:
                    TreadmillTileView(metrics: store.workoutMetrics)
                default:
                    EmptyView()
                }
            }

            if store.phaseStopwatch.isManagingPhase {
                StopwatchView(store: store.scope(state: \.phaseStopwatch, action: \.phaseStopwatch))
            }

            phasePanelSection

            Spacer()
        }
        .padding([.leading, .trailing], 8)
    }

    // MARK: - Landscape

    private var landscapeBody: some View {
        GeometryReader { geo in
            let spacing: CGFloat = 8
            let mainWidth = (geo.size.width - spacing) * 0.75

            HStack(spacing: spacing) {
                landscapeMetricsCard
                    .frame(width: mainWidth)
                VStack(spacing: spacing) {
                    landscapeSecondaryCard("MAX HR",
                                           data: store.sessionMaxHeartRate)
                    landscapeSecondaryCard("AVG HR",
                                           data: store.sessionAverageHeartRate)
                }
            }
            .frame(maxHeight: .infinity)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 36)
        .statusBarHidden()
    }
    
    // MARK: - SubView
    
    private var workoutMetricsCard: some View {
        GroupBox {
            VStack {
                heartRateView
                Spacer().frame(height: 10)
                currentHeartRatePercentageView
                activeEnergyBurnedView
                Spacer().frame(height: 20)
                bottomRow
            }
        }
        .styledGroupBox()
        .overlay {
            if store.currentHeartRateZone != .resting {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(store.currentHeartRateZone.color.opacity(0.3),
                            lineWidth: 1)
            }
        }
    }
    
    private func secondaryMetricCard(_ title: String, data: Int) -> some View {
        GroupBox {
            VStack(spacing: 4) {
                Text(title)
                    .font(.caption)
                    .textCase(.uppercase)
                    .foregroundStyle(.secondary)
                Text(data.formatted(.number))
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .monospacedDigit()
                    .foregroundStyle(.primary)
                    .contentTransition(.numericText(value: Double(data)))
                    .animation(.snappy(duration: 0.3), value: data)
            }
            .frame(maxWidth: .infinity)
            .multilineTextAlignment(.center)
        }
        .styledGroupBox()
    }
    
    /// Stale sensor (IOS-00100-B): the value on screen is the LAST KNOWN reading,
    /// not a live one — grey it out (not "—", which would read as a crash) and
    /// swap the pulsing heart for a slashed one.
    private var heartRateView: some View {
        HStack {
            Image(systemName: store.isSensorStale ? "heart.slash" : "heart.fill")
                .foregroundStyle(store.isSensorStale ? Color.gray : Color.red)
                .font(.system(.title2, design: .rounded))
                .symbolEffect(.pulse, options: .repeating, value: store.workoutMetrics.heartRate)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(store.workoutMetrics.heartRate.formatted(.number.precision(.fractionLength(0))))
                    .font(.system(.title2, design: .rounded, weight: .semibold).monospacedDigit())
                    .foregroundStyle(store.isSensorStale ? .secondary : .primary)
                    .contentTransition(.numericText(value: store.workoutMetrics.heartRate))
                    .animation(.snappy(duration: 0.3), value: store.workoutMetrics.heartRate)
                Text("BPM")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()

            zoneNameLabel
        }
    }

    /// Zone name badge — hidden in `.resting`: below Zone 1 there is no training
    /// zone to advertise mid-workout (warm-up, rest between sets); the % value
    /// and the zone description underneath still tell the story.
    @ViewBuilder
    private var zoneNameLabel: some View {
        if store.currentHeartRateZone != .resting {
            Text(store.currentHeartRateZone.title)
                .font(.title3.weight(.semibold))
                .foregroundStyle(store.currentHeartRateZone.color)
        }
    }

    private var currentHeartRatePercentageView: some View {
        VStack(spacing: 5) {
            Text("\(store.currentHeartRatePercentage)%")
                .font(.system(size: 60, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.primary)
                .contentTransition(.numericText(value: Double(store.currentHeartRatePercentage)))
                .animation(.snappy(duration: 0.3), value: store.currentHeartRatePercentage)
        }
    }
    
    private var activeEnergyBurnedView: some View {
        HStack(spacing: 4) {
            Image(systemName: "flame.fill")
                .foregroundStyle(.pink)
                .font(.system(.body, design: .rounded))
            Text(Measurement(value: store.workoutMetrics.activeEnergy, unit: .kilocalories).formatted(MetricFormatter.workoutEnergy))
                .font(.system(.title3, design: .rounded, weight: .semibold).monospacedDigit())
                .foregroundStyle(.primary)
                .contentTransition(.numericText(value: store.workoutMetrics.activeEnergy))
                .animation(.snappy(duration: 0.3), value: store.workoutMetrics.activeEnergy)
            VStack(alignment: .leading, spacing: 0) {
                Text("Active")
                Text("Energy")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }
    
    /// Bottom row: effort points (leading) + zone description (trailing). Zone name
    /// sits top-right next to the heart rate.
    private var bottomRow: some View {
        HStack(alignment: .bottom) {
            effortPointsView
            Spacer()
            Text(store.currentHeartRateZone.description)
                .font(.caption)
                .foregroundStyle(.secondary)
                .textCase(.lowercase)
                .multilineTextAlignment(.trailing)
        }
    }

    /// Live effort points counter (Myzone-style) — rewards time spent in HR zones.
    private var effortPointsView: some View {
        HStack(spacing: 4) {
            Image(systemName: "bolt.fill")
                .foregroundStyle(.yellow)
                .font(.system(.body, design: .rounded))
            Text(store.effortPoints.points.formatted(.number))
                .font(.system(.title3, design: .rounded, weight: .semibold).monospacedDigit())
                .foregroundStyle(.primary)
                .contentTransition(.numericText(value: Double(store.effortPoints.points)))
                .animation(.snappy(duration: 0.3), value: store.effortPoints.points)
            Text(String(localized: "pts", bundle: .main))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
    
    // MARK: - Landscape Cards

    private var landscapeMetricsCard: some View {
        VStack(spacing: 0) {
            landscapeHeaderView
            Spacer()
            landscapePercentageView
            landscapeEnergyView
            Spacer()
            landscapeBottomRow
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .glassEffect(in: RoundedRectangle(cornerRadius: 24))
    }

    private var landscapeHeaderView: some View {
        HStack(alignment: .top) {
            landscapeHeartRateView
            Spacer()
            zoneNameLabel
        }
    }

    private var landscapeHeartRateView: some View {
        HStack(spacing: 4) {
            Image(systemName: "heart.fill")
                .foregroundStyle(.red)
                .font(.system(.title3, design: .rounded))
                .symbolEffect(.pulse, options: .repeating, value: store.workoutMetrics.heartRate)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(store.workoutMetrics.heartRate.formatted(.number.precision(.fractionLength(0))))
                    .font(.system(.title3, design: .rounded, weight: .semibold).monospacedDigit())
                    .foregroundStyle(.primary)
                    .contentTransition(.numericText(value: store.workoutMetrics.heartRate))
                    .animation(.snappy(duration: 0.3), value: store.workoutMetrics.heartRate)
                Text("BPM")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var landscapePercentageView: some View {
        Text("\(store.currentHeartRatePercentage)%")
            .font(.system(size: 110, weight: .semibold, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(.primary)
            .contentTransition(.numericText(value: Double(store.currentHeartRatePercentage)))
            .animation(.snappy(duration: 0.3), value: store.currentHeartRatePercentage)
    }

    private var landscapeEnergyView: some View {
        HStack(spacing: 6) {
            Image(systemName: "flame.fill")
                .foregroundStyle(.pink)
                .font(.system(size: 24, design: .rounded))
            Text(Measurement(value: store.workoutMetrics.activeEnergy, unit: .kilocalories).formatted(MetricFormatter.workoutEnergy))
                .font(.system(size: 32, weight: .semibold, design: .rounded).monospacedDigit())
                .foregroundStyle(.primary)
                .contentTransition(.numericText(value: store.workoutMetrics.activeEnergy))
                .animation(.snappy(duration: 0.3), value: store.workoutMetrics.activeEnergy)
            VStack(alignment: .leading, spacing: 0) {
                Text("Active")
                Text("Energy")
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
    }

    /// Bottom row (landscape): effort points (leading) + zone description (trailing).
    private var landscapeBottomRow: some View {
        HStack(alignment: .bottom) {
            effortPointsView
            Spacer()
            Text(store.currentHeartRateZone.description)
                .font(.caption)
                .foregroundStyle(.secondary)
                .textCase(.lowercase)
                .multilineTextAlignment(.trailing)
        }
    }

    private func landscapeSecondaryCard(_ title: String, data: Int) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .textCase(.uppercase)
                .foregroundStyle(.secondary)
            Text(data.formatted(.number))
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.primary)
                .contentTransition(.numericText(value: Double(data)))
                .animation(.snappy(duration: 0.3), value: data)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .glassEffect(in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Phase Panel

    @ViewBuilder
    private var phasePanelSection: some View {
        if !store.phaseStopwatch.isManagingPhase,
           let phasePanelStore = store.scope(state: \.phasePanel, action: \.phasePanel) {
            PhasePanelView(store: phasePanelStore)
                .frame(minHeight: 180)
        }
    }

}

// MARK: - Styling

/// Stale sensor: desaturate the WHOLE screen — zone gradient included —
/// mirroring the GymRoom tile treatment (`AthleteTileView`, 0.35), so both
/// surfaces speak the same visual language for "data not live". The small
/// cues alone (grey bpm + heart.slash) were too subtle to notice mid-workout
/// at arm's length.
///
/// The filter is attached ONLY while stale — an always-on `.saturation(1.0)`
/// would keep a color-matrix pass in the render tree of the app's hottest
/// screen for the 99% of session time when it is a visual no-op.
private struct StaleDesaturation: ViewModifier {

    let isStale: Bool

    func body(content: Content) -> some View {
        if isStale {
            content.saturation(0.35)
        } else {
            content
        }
    }
}

#Preview("without plan") {
    NavigationStack {
        LiveSessionView(
            store: Store(initialState: LiveSessionFeature.State()) {
                LiveSessionFeature()
            }
        )
    }
}

#Preview("with stopwatch") {
    var state = LiveSessionFeature.State()
    state.userStopwatch.isVisible = true
    return NavigationStack {
        LiveSessionView(
            store: Store(initialState: state) {
                LiveSessionFeature()
            }
        )
    }
}

#Preview("cycling") {
    NavigationStack {
        LiveSessionView(store: Store(initialState: .cyclingPreview) { LiveSessionFeature() })
    }
}

#Preview("with plan") {
    let phases = TrainingSession.previewTrainingSession.phases
    var state = LiveSessionFeature.State()
    state.phasePanel = PhasePanelFeature.State(phases: phases)
    return NavigationStack {
        LiveSessionView(
            store: Store(initialState: state) {
                LiveSessionFeature()
            }
        )
    }
}

extension LiveSessionFeature.State {

    /// Mid-ride cycling session — feeds the "cycling" preview above.
    fileprivate static var cyclingPreview: Self {
        var state = LiveSessionFeature.State()
        state.currentHeartRateZone = .fatBurning
        state.currentHeartRatePercentage = 64
        state.sessionAverageHeartRate = 124
        state.sessionMaxHeartRate = 152
        state.selectedWorkout = .cycling
        state.workoutMetrics = WorkoutMetrics(
            averageHeartRate: 128,
            heartRate: 132,
            activeEnergy: 240,
            distance: 5_820,
            currentSpeed: 6.75,
            averageSpeed: 5.94,
            maxSpeed: 9.06,
            recentAverageSpeed: 6.33,
            lastKilometerSpeed: 6.53
        )
        return state
    }
}

// MARK: - Sensor Stale Preview (IOS-00100-B)

/// BLE strap out of range: whole-screen desaturation (0.35, mirrors the GymRoom
/// tile) + heart.slash + greyed last-known HR. Compare against "Sensor live
/// (same state)" below — identical values, only the flag differs, so flipping
/// between the two canvases shows exactly what the stale treatment dims.
#Preview("Sensor stale (IOS-00100)") {
    var state = LiveSessionFeature.State()
    state.currentHeartRateZone = .fatBurning
    state.workoutMetrics = WorkoutMetrics(averageHeartRate: 128, heartRate: 116, activeEnergy: 240)
    state.currentHeartRatePercentage = 62
    state.sessionAverageHeartRate = 124
    state.sessionMaxHeartRate = 158
    state.isSensorStale = true
    return NavigationStack {
        LiveSessionView(store: Store(initialState: state) { LiveSessionFeature() })
    }
}

/// Baseline twin of "Sensor stale (IOS-00100)" — the same session values with
/// a live sensor. Kept adjacent so the canvas pair reads as before/after.
#Preview("Sensor live (same state)") {
    var state = LiveSessionFeature.State()
    state.currentHeartRateZone = .fatBurning
    state.workoutMetrics = WorkoutMetrics(averageHeartRate: 128, heartRate: 116, activeEnergy: 240)
    state.currentHeartRatePercentage = 62
    state.sessionAverageHeartRate = 124
    state.sessionMaxHeartRate = 158
    return NavigationStack {
        LiveSessionView(store: Store(initialState: state) { LiveSessionFeature() })
    }
}

// MARK: - Heart Rate Zone Previews

#Preview("Resting") {
    var state = LiveSessionFeature.State()
    state.currentHeartRateZone = .resting
    state.workoutMetrics = WorkoutMetrics(averageHeartRate: 0, heartRate: 72, activeEnergy: 0)
    state.currentHeartRatePercentage = 38
    state.sessionAverageHeartRate = 70
    state.sessionMaxHeartRate = 75
    return NavigationStack {
        LiveSessionView(store: Store(initialState: state) { LiveSessionFeature() })
    }
}

#Preview("Zone 1") {
    var state = LiveSessionFeature.State()
    state.currentHeartRateZone = .recovery
    state.workoutMetrics = WorkoutMetrics(averageHeartRate: 0, heartRate: 108, activeEnergy: 85)
    state.currentHeartRatePercentage = 55
    state.sessionAverageHeartRate = 102
    state.sessionMaxHeartRate = 112
    return NavigationStack {
        LiveSessionView(store: Store(initialState: state) { LiveSessionFeature() })
    }
}

#Preview("Zone 2") {
    var state = LiveSessionFeature.State()
    state.currentHeartRateZone = .fatBurning
    state.workoutMetrics = WorkoutMetrics(averageHeartRate: 0, heartRate: 126, activeEnergy: 210)
    state.currentHeartRatePercentage = 65
    state.sessionAverageHeartRate = 118
    state.sessionMaxHeartRate = 130
    return NavigationStack {
        LiveSessionView(store: Store(initialState: state) { LiveSessionFeature() })
    }
}

#Preview("Zone 3") {
    var state = LiveSessionFeature.State()
    state.currentHeartRateZone = .aerobic
    state.workoutMetrics = WorkoutMetrics(averageHeartRate: 0, heartRate: 148, activeEnergy: 380)
    state.currentHeartRatePercentage = 75
    state.sessionAverageHeartRate = 140
    state.sessionMaxHeartRate = 155
    return NavigationStack {
        LiveSessionView(store: Store(initialState: state) { LiveSessionFeature() })
    }
}

#Preview("Zone 4") {
    var state = LiveSessionFeature.State()
    state.currentHeartRateZone = .threshold
    state.workoutMetrics = WorkoutMetrics(averageHeartRate: 0, heartRate: 168, activeEnergy: 520)
    state.currentHeartRatePercentage = 85
    state.sessionAverageHeartRate = 155
    state.sessionMaxHeartRate = 172
    // ~45 min across zones — effort points counter shows a realistic total.
    for _ in 0..<10 { state.effortPoints.add(bpm: 125, duration: 60, maxHR: 198) }
    for _ in 0..<20 { state.effortPoints.add(bpm: 150, duration: 60, maxHR: 198) }
    for _ in 0..<15 { state.effortPoints.add(bpm: 168, duration: 60, maxHR: 198) }
    return NavigationStack {
        LiveSessionView(store: Store(initialState: state) { LiveSessionFeature() })
    }
}

#Preview("Zone 5") {
    var state = LiveSessionFeature.State()
    state.currentHeartRateZone = .anaerobic
    state.workoutMetrics = WorkoutMetrics(averageHeartRate: 0, heartRate: 185, activeEnergy: 680)
    state.currentHeartRatePercentage = 95
    state.sessionAverageHeartRate = 170
    state.sessionMaxHeartRate = 188
    return NavigationStack {
        LiveSessionView(store: Store(initialState: state) { LiveSessionFeature() })
    }
}
