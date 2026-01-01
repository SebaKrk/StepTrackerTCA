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

@ViewAction(for: ActivityDetailsFeature.self)
struct ActivityDetailsView: View {
    
    // MARK: - Properties
    
    @Bindable var store: StoreOf<ActivityDetailsFeature>
    
    // MARK: - Body
    
    var body: some View {
        rootView
            .padding([.leading, .trailing], 8)
            .navigationTitle("\(store.workout.startDate.formatted(date: .abbreviated, time: .omitted))")
            .background(LinearGradient(colors: [store.color.opacity(0.25), .clear], startPoint: .topLeading, endPoint: .bottomTrailing))
            .onAppear {
                send(.viewDidAppear)
            }
    }
    
    private var rootView: some View {
        ScrollView {
            VStack(spacing: 8) {
                headerTitle
                energySection
                heartRateSection
                if let distribution = store.zoneDistribution {
                    zoneDistributionSection(distribution)
                }
                trainingLoadSection
                stressRecoverySection
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
            Text(store.workout.workoutActivityType.name)
                .foregroundColor(.primary)
                .font(.title2)
                .bold()
            Text(formattedDuration)
                .foregroundColor(.gray)
                .font(.footnote)
            Spacer()
            Image(systemName: store.workout.workoutActivityType.iconNameSimple)
                .resizable()
                .scaledToFit()
                .foregroundColor(.primary)
                .frame(width: 25, height: 25)
        }
    }
    
    private var headerWorkoutDates: some View {
        HStack {
            Text(store.workout.startDate,
                 format: .dateTime.hour().minute().second())
            Text("-")
            Text(store.workout.endDate,
                 format: .dateTime.hour().minute().second())
            Spacer()
            Text(store.workout.startDate, format: .dateTime.weekday(.wide))
        }
        .font(.footnote)
        .foregroundStyle(.secondary)
    }
    
    // MARK: - Energy Section
    
    private var energySection: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 4),
                GridItem(.flexible(), spacing: 4)
            ],
            spacing: 4
        ) {
            simpleMetricCard(
                title: "Calories Active",
                value: formattedCalories,
                unit: "kcal",
                icon: "flame.fill"
            )
            simpleMetricCard(
                title: "METs",
                value: formattedMETs,
                unit: "",
                icon: "bolt.fill"
            )
        }
    }
    
    // MARK: - Heart Rate Section
    
    private var heartRateSection: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 4),
                GridItem(.flexible(), spacing: 4)
            ],
            spacing: 4
        ) {
            simpleMetricCard(
                title: "Avg HR",
                value: formattedAvgHR,
                unit: "bpm",
                icon: "heart.fill"
            )
            simpleMetricCard(
                title: "Max HR",
                value: formattedMaxHR,
                unit: "bpm",
                icon: "heart.fill"
            )
        }
    }
    
    // MARK: - Training Load Section
    
    private var trainingLoadSection: some View {
        trimpCard
    }
    
    // MARK: - Stress & Recovery Section
    
    private var stressRecoverySection: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 4),
                GridItem(.flexible(), spacing: 4)
            ],
            spacing: 4
        ) {
            descriptiveMetricCard(
                title: "hrTSS",
                value: formattedHRTSS,
                unit: "",
                label: store.hrTSSLevel?.recoveryEstimate ?? "",
                labelColor: store.hrRecoveryLevel?.color ?? .gray,
                icon: "waveform.path.ecg"
            )
            .contextMenu {
                if let hrTSSLevel = store.hrTSSLevel {
                    Text(hrTSSLevel.description)
                }
            }
            descriptiveMetricCard(
                title: "HR Recovery",
                value: formattedHRRecovery,
                unit: "bpm",
                label: store.hrRecoveryLevel?.rawValue ?? "",
                labelColor: store.hrRecoveryLevel?.color ?? .gray,
                icon: "arrow.down.heart.fill"
            )
            .contextMenu {
                if let hrRecoveryLevel = store.hrRecoveryLevel {
                    Text(hrRecoveryLevel.description)
                }
            }
        }
    }
    
    // MARK: - Card Components
    
    /// Simple workout metric card with value and unit.
    private func simpleMetricCard(
        title: String,
        value: String,
        unit: String,
        icon: String
    ) -> some View {
        GroupBox {
            HStack {
                Text(value)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                Text(unit)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        } label: {
            Label(title, systemImage: icon)
                .font(.caption)
                .foregroundColor(.secondary)
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
                if !label.isEmpty {
                    Text(label)
                        .font(.caption)
                        .foregroundColor(labelColor)
                }
            }
        } label: {
            Label(title, systemImage: icon)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .styledGroupBox()
    }
    
    /// Detailed TRIMP training load card with progress bar and comparison.
    private var trimpCard: some View {
        GroupBox {
            VStack(spacing: 12) {
                HStack {
                    Text("TRIMP:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(formattedTRIMP)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    trimpProgressBar
                    
                    if let level = store.trimpLevel {
                        Text(level.rawValue)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(level.color)
                    }
                }
                
                Divider()
                
                HStack {
                    HStack(spacing: 4) {
                        Text("vs 7d:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("—")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Text("Recovery:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(store.trimpLevel?.recoveryEstimate ?? "—")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                }
            }
        } label: {
            Label("Training Load", systemImage: "figure.run")
                .font(.headline)
        }
        .styledGroupBox()
    }
    
    private var trimpProgressBar: some View {
        GeometryReader { geometry in
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.opacity(0.3))
                .overlay(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(store.trimpLevel?.color ?? .gray)
                        .frame(width: geometry.size.width * trimpProgress)
                }
        }
        .frame(width: 80, height: 8)
    }
    
    // MARK: - Zone Distribution
    
    private func zoneDistributionSection(_ distribution: [HeartRateZone: TimeInterval]) -> some View {
        GroupBox {
            heartRateZone(distribution)
        } label: {
            Label("Heart Rate Zones", systemImage: "heart.text.square")
                .font(.headline)
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
            Text("Primary Zone:")
                .font(.caption)
            
            if let zoneInfo = store.primaryZoneInfo {
                Text(zoneInfo.zone.rawValue)
                    .font(.caption)
                    .bold()
                    .foregroundStyle(zoneInfo.zone.color)
            } else {
                Text("–")
                    .font(.caption)
                    .bold()
            }
            
            Spacer()
            
            Text("Time in zone:")
                .font(.caption)
            
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
        .padding(4)
    }
    
    private func zoneRow(zone: HeartRateZone, duration: TimeInterval, total: TimeInterval) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Circle()
                    .fill(zone.color)
                    .frame(width: 10, height: 10)
                
                Text(zone.rawValue)
                    .font(.subheadline)
                
                Spacer()
                
                Text(formatDuration(duration))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
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
    
    private var formattedTRIMP: String {
        guard let trimp = store.trimp else { return "—" }
        return "\(Int(trimp))"
    }
    
    private var formattedHRTSS: String {
        guard let hrTSS = store.hrTSS else { return "—" }
        return "\(Int(hrTSS))"
    }
    
    private var formattedHRRecovery: String {
        guard let hrRecovery = store.hrRecovery else { return "—" }
        return "\(hrRecovery)"
    }
    
    private var trimpProgress: Double {
        guard let trimp = store.trimp else { return 0 }
        return min(trimp / 400, 1.0)
    }
    
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return "\(minutes)m \(secs)s"
    }
}

//
//ActivityDetailsFeature (parent - koordynator)
//│
//├── State:
//│   ├── workout: HKWorkout
//│   ├── maxHeartRate: Double
//│   ├── color: Color (shared)
//│   │
//│   └── Children:
//│       ├── heartRateAnalysis: HeartRateAnalysisFeature.State?
//│       └── routeMap: RouteMapFeature.State?
//│
//├── Actions:
//│   ├── view(.viewDidAppear)
//│   ├── internal(.loadChildren)
//│   ├── heartRateAnalysis(HeartRateAnalysisFeature.Action)
//│   └── routeMap(RouteMapFeature.Action)
//│
//│
//├─────────────────────────────────────────────────────────────
//│
//├── HeartRateAnalysisFeature (child)
//│   │
//│   ├── State:
//│   │   ├── isLoading: Bool
//│   │   ├── zoneDistribution: [HeartRateZone: TimeInterval]?
//│   │   ├── chartData: [HeartRateChartPoint]?  // później
//│   │   └── error: String?
//│   │
//│   ├── Actions:
//│   │   ├── view(.viewDidAppear)
//│   │   ├── internal(.loadData(workout, maxHR))
//│   │   ├── internal(.dataLoaded(distribution, chartData))
//│   │   └── internal(.loadingFailed(error))
//│   │
//│   └── View: HeartRateAnalysisView
//│       ├── Zone distribution bars
//│       └── HR Chart (później)
//│
//│
//├─────────────────────────────────────────────────────────────
//│
//└── RouteMapFeature (child)
//    │
//    ├── State:
//    │   ├── isLoading: Bool
//    │   ├── coordinates: [CLLocationCoordinate2D]?
//    │   ├── region: MKCoordinateRegion?
//    │   └── error: String?
//    │
//    ├── Actions:
//    │   ├── view(.viewDidAppear)
//    │   ├── internal(.loadRoute(workout))
//    │   ├── internal(.routeLoaded(coordinates))
//    │   └── internal(.loadingFailed(error))
//    │
//    └── View: RouteMapView
//        ├── MKMapView z trasą
//        └── Start/End markers
