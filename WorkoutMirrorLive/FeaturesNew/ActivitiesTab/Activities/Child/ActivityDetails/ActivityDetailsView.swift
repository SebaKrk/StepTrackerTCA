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
            VStack {
                headerTitle
                statsGridView
                if let distribution = store.zoneDistribution {
                    zoneDistributionSection(distribution)
                }
            }
        }
    }
    
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
            Text(store.workout.startDate, format: .dateTime.weekday(.wide))
                .font(.footnote)
                .foregroundStyle(.secondary)
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
            Text(formattedDuration)
                .foregroundColor(.gray)
                .font(.footnote)
        }
        .font(.footnote)
        .foregroundStyle(.secondary)
    }
    
    private var statsGridView: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 4),
                GridItem(.flexible(), spacing: 4)
            ],
            spacing: 4
        ) {
            workoutCardView(title: "Calories Total", value: formattedTotalCalories, unit: "kcla", icon: "flame")
            workoutCardView(title: "Calories Active", value: formattedCalories, unit: "kcla", icon: "flame.fill")
            workoutCardView(title: "Avg HR", value: formattedAvgHR, unit: "bpm", icon: "heart.fill")
            workoutCardView(title: "Max HR", value: formattedMaxHR, unit: "bpm", icon: "heart.fill")
        }
    }
    
    // cal total
    // cal active
    // trimp
    //hr tss
    // hr recovery - 1 min
    // v02 max
    // METs (Metabolic Equivalent of Task)
    
    private func workoutCardView(title: String,
                                 value: String,
                                 unit: String,
                                 icon: String) -> some View {
        GroupBox {
            VStack(spacing: 12) {
                HStack {
                    Text(value)
                        .font(.title)
                        .foregroundColor(.primary)
                        .bold()
                    Text(unit)
                        .foregroundColor(.gray)
                }
            }
        } label: {
            VStack {
                HStack {
                    Group {
                        Image(systemName: icon)
                        Text(title)
                        Spacer()
                    }
                    .foregroundColor(.gray)
                    .font(.caption)
                }
                Divider()
            }
        }
        .styledGroupBox()
    }
    
    // MARK: - Zone Distribution
    
    private func zoneDistributionSection(_ distribution: [HeartRateZone: TimeInterval]) -> some View {
        GroupBox {
            heartRateZone(distribution)
        } label: {
            VStack(alignment: .leading) {
                Label("Heart Rate Zones", systemImage: "heart.text.square")
                    .foregroundColor(.gray)
                    .font(.caption)
                Divider()
            }
        }
        .backgroundStyle(.clear)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(.gray.opacity(0.5), lineWidth: 0.5)
                .fill(Color(.secondarySystemBackground).gradient.opacity(0.5))
        )
    }
    
    private func heartRateZone(_ distribution: [HeartRateZone: TimeInterval]) -> some View {
        DisclosureGroup(isExpanded:  Binding(
            get: { store.isExpandZone },
            set: { isExpanded in
                if isExpanded {
                    send(.zoneDiscusserButtonTapped(true))
                } else {
                    send(.zoneDiscusserButtonTapped(false))
                }
            }
        )) {
            if store.isExpandZone {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(HeartRateZone.allCases) { zone in
                        zoneRow(zone: zone, duration: distribution[zone] ?? 0, total: totalZoneDuration(distribution))
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
    
    private var formattedTotalCalories: String {
        let active = calories(for: HKQuantityTypeIdentifier.activeEnergyBurned)
        let basal = calories(for: HKQuantityTypeIdentifier.basalEnergyBurned)
        let total = active + basal
        
        return total > 0 ? "\(Int(total))" : "—"
    }
    
    private func calories(
        for identifier: HKQuantityTypeIdentifier
    ) -> Double {
        store.workout.statistics(for: HKQuantityType(identifier))?
            .sumQuantity()?
            .doubleValue(for: .kilocalorie()) ?? 0
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
    
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return "\(minutes)m \(secs)s"
    }
    
    private func totalZoneDuration(_ distribution: [HeartRateZone: TimeInterval]) -> TimeInterval {
        distribution.values.reduce(0, +)
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
