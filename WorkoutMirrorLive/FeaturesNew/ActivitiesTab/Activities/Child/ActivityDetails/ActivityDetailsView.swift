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
        ScrollView {
            VStack(spacing: 16) {
                headerSection
                statsGrid
                
                if let distribution = store.zoneDistribution {
                    zoneDistributionSection(distribution)
                }
                
                // TODO: HR Chart
                // TODO: Map
            }
            .padding()
        }
        .background(LinearGradient(colors: [store.color.opacity(0.25), .clear], startPoint: .topLeading, endPoint: .bottomTrailing))
        .navigationTitle(store.workout.workoutActivityType.name)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            send(.viewDidAppear)
        }
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        HStack {
            Image(systemName: store.workout.workoutActivityType.iconNameSimple)
                .resizable()
                .scaledToFit()
                .frame(width: 50, height: 50)
                .foregroundStyle(store.color)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(store.workout.workoutActivityType.name)
                    .font(.title2)
                    .bold()
                Text(store.workout.startDate.formatted(date: .abbreviated, time: .shortened))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }
    
    // MARK: - Stats Grid
    
    private var statsGrid: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 8),
                GridItem(.flexible(), spacing: 8)
            ],
            spacing: 8
        ) {
            statBox(title: "Duration", value: formattedDuration, icon: "clock")
            statBox(title: "Calories", value: formattedCalories, icon: "flame.fill")
            statBox(title: "Avg HR", value: formattedAvgHR, icon: "heart.fill")
            statBox(title: "Max HR", value: formattedMaxHR, icon: "heart.fill")
        }
    }
    
    private func statBox(title: String, value: String, icon: String) -> some View {
        GroupBox {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(store.color)
                
                Text(value)
                    .font(.title)
                    .bold()
                
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .backgroundStyle(.clear)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(.gray.opacity(0.5), lineWidth: 0.5)
                .fill(Color(.secondarySystemBackground).gradient.opacity(0.5))
        )
    }
    
    // MARK: - Zone Distribution
    
    private func zoneDistributionSection(_ distribution: [HeartRateZone: TimeInterval]) -> some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(HeartRateZone.allCases) { zone in
                    zoneRow(zone: zone, duration: distribution[zone] ?? 0, total: totalZoneDuration(distribution))
                }
            }
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
