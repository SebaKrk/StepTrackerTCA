//
//  ActivityDetailsView.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 26/12/2025.
//

import ComposableArchitecture
import SwiftUI
import SharedModels
import HealthKit
import MapKit

@ViewAction(for: ActivityDetailsFeature.self)
struct ActivityDetailsView: View {
    
    // MARK: - Properties
    
    @Bindable var store: StoreOf<ActivityDetailsFeature>
    
    // MARK: - Body
    
    var body: some View {
        rootView
            .padding([.leading, .trailing], 8)
            .navigationTitle(navigationTitleText)
            .background(LinearGradient(colors: [store.color.opacity(0.25), .clear], startPoint: .topLeading, endPoint: .bottomTrailing))
            .toolbar { linkTemplateToolbarItem }
            .onAppear {
                send(.viewDidAppear)
            }
            .navigationDestination(
                item: $store.scope(
                    state: \.destination?.metricDetail,
                    action: \.destination.metricDetail)) { store in
                        MetricDetailView(store: store)
                    }
            .sheet(
                item: $store.scope(
                    state: \.destination?.linkTemplate,
                    action: \.destination.linkTemplate)) { store in
                        TemplatePickerView(store: store)
                    }
            .fullScreenCover(
                item: $store.scope(
                    state: \.destination?.summary,
                    action: \.destination.summary)) { store in
                        NavigationStack {
                            SummaryView(store: store)
                        }
                    }
    }

    // MARK: - Link Template Toolbar Item

    /// Toolbar button:
    /// - "Podpnij plan" gdy workout nie ma podpiętego planu (`loadState == .notFound`)
    ///   — escape hatch dla nieudanego `.saving → .summary` flow.
    /// - "Edytuj wynik" gdy workout ma już podpięty plan (`loadState == .loaded(_)`)
    ///   — pre-fill SummaryView istniejącymi wynikami, user może modyfikować.
    /// Loading/failed → button schowany.
    @ToolbarContentBuilder
    private var linkTemplateToolbarItem: some ToolbarContent {
        switch store.planScore.loadState {
        case .notFound:
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    send(.linkTemplateTapped)
                } label: {
                    Text(linkTemplateButtonTitle)
                }
            }
        case .loaded:
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    send(.editExistingScoreTapped)
                } label: {
                    Text(editScoreButtonTitle)
                }
            }
        case .loading, .failed:
            ToolbarItem(placement: .topBarTrailing) { EmptyView() }
        }
    }

    private var linkTemplateButtonTitle: String {
        String(localized: "Podpnij plan")
    }

    private var editScoreButtonTitle: String {
        String(localized: "Edytuj wynik")
    }
    
    private var navigationTitleText: String {
        store.workout.startDate.formatted(date: .abbreviated, time: .omitted)
    }

    private var rootView: some View {
        ScrollView {
            VStack(spacing: 8) {
                headerTitle
                energySection
                heartRateSection
                hrRangeChartSection()
                if let distribution = store.zoneDistribution {
                    zoneDistributionSection(distribution)
                }
                performanceMetricsSection
                locationSection
                planScoreSection
            }
        }
    }
    
    // MARK: - Header
    
    private var headerTitle: some View {
        VStack {
            headerWorkoutActivityType
            headerWorkoutDates
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(.gray.opacity(0.5), lineWidth: 0.5)
                .fill(Color(.secondarySystemBackground).gradient.opacity(0.5))
        )
    }
    
    private var headerWorkoutActivityType: some View {
        HStack {
            headerActivityTypeName
            headerDurationText
            Spacer()
            headerActivityTypeIcon
        }
    }

    private var headerActivityTypeName: some View {
        Text(store.workout.workoutActivityType.name)
            .foregroundColor(.primary)
            .font(.title2)
            .bold()
    }

    private var headerDurationText: some View {
        Text(formattedDuration)
            .foregroundColor(.gray)
            .font(.footnote)
    }

    private var headerActivityTypeIcon: some View {
        Image(systemName: store.workout.workoutActivityType.iconNameSimple)
            .resizable()
            .scaledToFit()
            .foregroundColor(.primary)
            .frame(width: 25, height: 25)
    }

    private var headerWorkoutDates: some View {
        HStack {
            headerStartTimeText
            Text("-")
            headerEndTimeText
            Spacer()
            headerWeekdayText
        }
        .font(.footnote)
        .foregroundStyle(.secondary)
    }

    private var headerStartTimeText: some View {
        Text(store.workout.startDate,
             format: .dateTime.hour().minute().second())
    }

    private var headerEndTimeText: some View {
        Text(store.workout.endDate,
             format: .dateTime.hour().minute().second())
    }

    private var headerWeekdayText: some View {
        Text(store.workout.startDate, format: .dateTime.weekday(.wide))
    }
    
    // MARK: - Energy Section
    
    private var energySection: some View {
        LazyVGrid(columns: twoColumnGrid, spacing: 4) {
            simpleMetricCard(
                title: String(localized: "Calories Active", bundle: .main),
                value: formattedCalories,
                unit: "kcal",
                icon: "flame.fill"
            )
            simpleMetricCard(
                title: String(localized: "METs", bundle: .main),
                value: formattedMETs,
                unit: "",
                icon: "bolt.fill"
            )
        }
    }
    
    // MARK: - Heart Rate Section
    
    private var heartRateSection: some View {
        LazyVGrid(columns: twoColumnGrid, spacing: 4) {
            simpleMetricCard(
                title: String(localized: "Avg HR", bundle: .main),
                value: formattedAvgHR,
                unit: "bpm",
                icon: "heart.fill"
            )
            simpleMetricCard(
                title: String(localized: "Max HR", bundle: .main),
                value: formattedMaxHR,
                unit: "bpm",
                icon: "heart.fill"
            )
        }
    }
    
    // MARK: - Performance Metrics Section
    
    private var performanceMetricsSection: some View {
        VStack(spacing: 4) {
            LazyVGrid(columns: twoColumnGrid, spacing: 4) {
                hrTSSCard
                intensityCard
            }
            LazyVGrid(columns: twoColumnGrid, spacing: 4) {
                hrRecoveryCard
                recoveryDemandCard
            }
        }
    }

    private var hrTSSCard: some View {
        tappableMetricCard(
            title: String(localized: "hrTSS", bundle: .main),
            value: formattedHRTSS,
            unit: "",
            label: store.hrTSSLevel?.recoveryEstimate ?? "",
            labelColor: store.hrTSSLevel?.color ?? .gray,
            icon: "figure.run"
        ) {
            if let hrTSS = store.hrTSS, let level = store.hrTSSLevel {
                send(.openMetricDetails(.hrTSS(value: hrTSS, level: level)))
            }
        }
    }

    private var intensityCard: some View {
        tappableMetricCard(
            title: String(localized: "Intensity", bundle: .main),
            value: formattedIntensityFactor,
            unit: "",
            label: store.intensityFactorLevel?.title ?? "",
            labelColor: store.intensityFactorLevel?.color ?? .gray,
            icon: "gauge.with.needle"
        ) {
            if let intensity = store.intensityFactor, let level = store.intensityFactorLevel {
                send(.openMetricDetails(.intensity(value: intensity, level: level)))
            }
        }
    }

    private var hrRecoveryCard: some View {
        tappableMetricCard(
            title: String(localized: "HR Recovery", bundle: .main),
            value: formattedHRRecovery,
            unit: "bpm",
            label: store.hrRecoveryLevel?.title ?? "",
            labelColor: store.hrRecoveryLevel?.color ?? .gray,
            icon: "arrow.down.heart.fill"
        ) {
            if let hrRecovery = store.hrRecovery, let level = store.hrRecoveryLevel {
                send(.openMetricDetails(.hrRecovery(value: hrRecovery, level: level)))
            }
        }
    }

    private var recoveryDemandCard: some View {
        tappableMetricCard(
            title: String(localized: "Recovery Demand", bundle: .main),
            value: store.recoveryDemandLevel?.valueString ?? "—",
            unit: store.recoveryDemandLevel?.unitString ?? "",
            label: store.recoveryDemandLevel?.title ?? "",
            labelColor: store.recoveryDemandLevel?.color ?? .gray,
            icon: "bed.double.fill"
        ) {
            if let recoveryDemand = store.recoveryDemand, let level = store.recoveryDemandLevel {
                send(.openMetricDetails(.recoveryDemand(value: recoveryDemand, level: level)))
            }
        }
    }
    
    private var twoColumnGrid: [GridItem] {
        [
            GridItem(.flexible(), spacing: 4),
            GridItem(.flexible(), spacing: 4)
        ]
    }

    // MARK: - Card Components

    private func cardValueWithUnit(value: String, unit: String) -> some View {
        HStack {
            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            if !unit.isEmpty {
                Text(unit)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }

    private func cardLabel(title: String, icon: String) -> some View {
        Label(title, systemImage: icon)
            .font(.caption)
            .foregroundColor(.secondary)
    }

    @ViewBuilder
    private func cardSubLabel(_ label: String, color: Color) -> some View {
        if !label.isEmpty {
            Text(label)
                .font(.caption)
                .foregroundColor(color)
        }
    }

    /// Simple workout metric card with value and unit.
    private func simpleMetricCard(
        title: String,
        value: String,
        unit: String,
        icon: String
    ) -> some View {
        GroupBox {
            cardValueWithUnit(value: value, unit: unit)
        } label: {
            cardLabel(title: title, icon: icon)
        }
        .styledGroupBox()
    }

    /// Metric card with value, unit and descriptive label.
    private func descriptiveMetricCard(
        title: String,
        value: String,
        unit: String,
        label: String,
        labelColor: Color = .secondary,
        icon: String
    ) -> some View {
        GroupBox {
            VStack(spacing: 4) {
                cardValueWithUnit(value: value, unit: unit)
                cardSubLabel(label, color: labelColor)
            }
        } label: {
            cardLabel(title: title, icon: icon)
        }
        .styledGroupBox()
    }

    /// Metric card with tappable title for navigation to details.
    private func tappableMetricCard(
        title: String,
        value: String,
        unit: String,
        label: String,
        labelColor: Color = .secondary,
        icon: String,
        onTitleTap: @escaping () -> Void
    ) -> some View {
        GroupBox {
            VStack(spacing: 4) {
                cardValueWithUnit(value: value, unit: unit)
                cardSubLabel(label, color: labelColor)
            }
            .frame(minHeight: 50)
        } label: {
            Button(action: onTitleTap) {
                HStack {
                    cardLabel(title: title, icon: icon)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .styledGroupBox()
    }
    
    // MARK: - Zone Distribution
    
    private func zoneDistributionSection(_ distribution: [HeartRateZone: TimeInterval]) -> some View {
        GroupBox {
            heartRateZone(distribution)
        } label: {
            Label(String(localized: "Heart Rate Zones", bundle: .main), systemImage: "heart.text.square")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .backgroundStyle(.clear)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(.gray.opacity(0.5), lineWidth: 0.5)
                .fill(Color(.secondarySystemBackground).gradient.opacity(0.5))
        )
    }
    
    private func heartRateZone(_ distribution: [HeartRateZone: TimeInterval]) -> some View {
        DisclosureGroup(isExpanded: Binding(
            get: { store.isExpandZone },
            set: { isExpanded in
                send(.zoneDiscusserButtonTapped(isExpanded))
            }
        )) {
            if store.isExpandZone {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(HeartRateZone.allCases) { zone in
                        zoneRow(
                            zone: zone,
                            duration: distribution[zone] ?? 0,
                            total: store.totalZoneDuration
                        )
                    }
                }
            }
        } label: {
            if !store.isExpandZone {
                primaryZone
            }
        }
    }
    
    private var primaryZone: some View {
        HStack {
            primaryZoneLabel
            primaryZoneValue
            Spacer()
            timeInZoneLabel
            timeInZoneValue
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(4)
    }

    private var primaryZoneLabel: some View {
        Text(String(localized: "Primary Zone", bundle: .main) + ":")
            .font(.caption)
    }

    @ViewBuilder
    private var primaryZoneValue: some View {
        if let zoneInfo = store.primaryZoneInfo {
            Text(zoneInfo.zone.title)
                .font(.caption)
                .bold()
                .foregroundStyle(zoneInfo.zone.color)
        } else {
            Text("–")
                .font(.caption)
                .bold()
        }
    }

    private var timeInZoneLabel: some View {
        Text(String(localized: "Time in zone", bundle: .main) + ":")
            .font(.caption)
    }

    @ViewBuilder
    private var timeInZoneValue: some View {
        if let zoneInfo = store.primaryZoneInfo {
            Text(formatDuration(zoneInfo.duration))
                .font(.caption)
                .bold()
        } else {
            Text("–")
                .font(.caption)
                .bold()
        }
    }
    
    private func zoneRow(zone: HeartRateZone, duration: TimeInterval, total: TimeInterval) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            zoneRowHeader(zone: zone, duration: duration)
            zoneProgressBar(zone: zone, duration: duration, total: total)
        }
    }

    private func zoneRowHeader(zone: HeartRateZone, duration: TimeInterval) -> some View {
        HStack {
            Circle()
                .fill(zone.color)
                .frame(width: 10, height: 10)
            Text(zone.title)
                .font(.subheadline)
            Spacer()
            Text(formatDuration(duration))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private func zoneProgressBar(zone: HeartRateZone, duration: TimeInterval, total: TimeInterval) -> some View {
        GeometryReader { geometry in
            RoundedRectangle(cornerRadius: 4)
                .fill(zone.color.opacity(0.3))
                .frame(width: geometry.size.width)
                .overlay(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(zone.color)
                        .frame(width: total > 0 ? geometry.size.width * (duration / total) : 0)
                }
        }
        .frame(height: 8)
    }
    
    @ViewBuilder
    private var locationSection: some View {
        if store.isLoadingLocation {
            loadingLocationView
        } else if let coordinates = store.routeCoordinates, !coordinates.isEmpty {
            if coordinates.count >= 2 {
                routeMapView(coordinates: coordinates)
            } else {
                singleLocationMapView(coordinate: coordinates[0])
            }
        }
    }
    
    private func routeMapView(coordinates: [CLLocationCoordinate2D]) -> some View {
        GroupBox {
            routeMap(coordinates: coordinates)
                .disabled(true)
                .frame(height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        } label: {
            routeLabelButton
        }
        .styledGroupBox()
    }

    private func routeMap(coordinates: [CLLocationCoordinate2D]) -> some View {
        Map {
            MapPolyline(coordinates: coordinates)
                .stroke(store.color, lineWidth: 3)
            if let start = coordinates.first {
                Annotation(String(localized: "Start", bundle: .main), coordinate: start) {
                    routeMarker(color: .green)
                }
            }
            if let end = coordinates.last {
                Annotation(String(localized: "Finish", bundle: .main), coordinate: end) {
                    routeMarker(color: .red)
                }
            }
        }
    }

    private func routeMarker(color: Color) -> some View {
        Circle()
            .fill(color)
            .stroke(.white, lineWidth: 2)
            .frame(width: 16, height: 16)
    }

    private var routeLabelButton: some View {
        Button {
            // TODO: - destination RoutDetails
        } label: {
            HStack {
                Label(String(localized: "Route", bundle: .main), systemImage: "figure.run")
                Spacer()
                Image(systemName: "chevron.right")
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
    }
    
    private func singleLocationMapView(coordinate: CLLocationCoordinate2D) -> some View {
        GroupBox {
            Map {
                Annotation(String(localized: "Workout", bundle: .main), coordinate: coordinate) {
                    Image(systemName: "figure.run.circle.fill")
                        .font(.title)
                        .foregroundStyle(store.color)
                }
            }
            .disabled(true)
            .frame(height: 150)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        } label: {
            HStack {
                Label(String(localized: "Localization", bundle: .main), systemImage: "location.fill")
                Spacer()
                Image(systemName: "chevron.right")
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .styledGroupBox()
    }
    
    private var loadingLocationView: some View {
        GroupBox {
            HStack {
                ProgressView()
                Text(String(localized: "Loading route...", bundle: .main))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 200)
        } label: {
            Label(String(localized: "Localization", bundle: .main), systemImage: "location.fill")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .styledGroupBox()
    }
    
    // MARK: - Plan Score

    private var planScoreSection: some View {
        ActivityPlanScoreView(store: store.scope(state: \.planScore, action: \.planScore))
    }

    // MARK: - Formatters
    
    private var formattedDuration: String {
        let minutes = Int(store.workout.duration) / 60
        return "\(minutes) min"
    }
    
    private var formattedCalories: String {
        guard let calories = store.workout.statistics(for: HKQuantityType(.activeEnergyBurned))?
            .sumQuantity()?
            .doubleValue(for: .kilocalorie()) else {
            return "—"
        }
        return "\(Int(calories))"
    }
    
    private var formattedAvgHR: String {
        guard let avgHR = store.workout.statistics(for: HKQuantityType(.heartRate))?
            .averageQuantity()?
            .doubleValue(for: .count().unitDivided(by: .minute())) else {
            return "—"
        }
        return "\(Int(avgHR))"
    }
    
    private var formattedMaxHR: String {
        guard let maxHR = store.workout.statistics(for: HKQuantityType(.heartRate))?
            .maximumQuantity()?
            .doubleValue(for: .count().unitDivided(by: .minute())) else {
            return "—"
        }
        return "\(Int(maxHR))"
    }
    
    private var formattedMETs: String {
        guard let mets = store.mets else { return "—" }
        return String(format: "%.1f", mets)
    }
    
    private var formattedHRTSS: String {
        guard let hrTSS = store.hrTSS else { return "—" }
        return "\(Int(hrTSS))"
    }
    
    private var formattedHRRecovery: String {
        guard let hrRecovery = store.hrRecovery else { return "—" }
        return "\(hrRecovery)"
    }
    
    private var formattedIntensityFactor: String {
        guard let intensityFactor = store.intensityFactor else { return "—" }
        return String(format: "%.2f", intensityFactor)
    }
    
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return "\(minutes)m \(secs)s"
    }

}

// MARK: - Preview

#Preview("without plan") {
    let workout = HKWorkout(
        activityType: .crossTraining,
        start: Date().addingTimeInterval(-3600),
        end: Date()
    )
    return NavigationStack {
        ActivityDetailsView(store: Store(
            initialState: ActivityDetailsFeature.State(workout: workout, maxHeartRate: 185)
        ) {
            ActivityDetailsFeature()
        } withDependencies: {
            $0.workoutPlanScoreClient.fetchByHKWorkoutId = { _ in nil }
        })
    }
}

#Preview("with plan") {
    let session = TrainingSession.previewTrainingSession
    let workout = HKWorkout(
        activityType: .crossTraining,
        start: Date().addingTimeInterval(-3600),
        end: Date()
    )
    let score = WorkoutPlanScore(
        trainingSessionId: session.id,
        hkWorkoutId: workout.uuid,
        results: session.workouts.map {
            WorkoutSessionResult(
                name: $0.name,
                description: $0.snapshotDescription,
                scoreResult: $0.name == "WOD 1" ? .custom("11:43") : .forLoad(weight: 80),
                note: ""
            )
        }
    )
    return NavigationStack {
        ActivityDetailsView(store: Store(
            initialState: ActivityDetailsFeature.State(workout: workout, maxHeartRate: 185)
        ) {
            ActivityDetailsFeature()
        } withDependencies: {
            $0.workoutPlanScoreClient.fetchByHKWorkoutId = { _ in score }
        })
    }
}
