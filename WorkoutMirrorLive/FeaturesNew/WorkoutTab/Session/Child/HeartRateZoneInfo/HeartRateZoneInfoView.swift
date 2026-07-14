//
//  HeartRateZoneInfoView.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 07/08/2025.
//

import ComposableArchitecture
import SwiftUI
import SharedModels

@ViewAction(for: HeartRateZoneInfoFeature.self)
struct HeartRateZoneInfoView: View {
    
    // MARK: - Properties
    
    @Bindable var store: StoreOf<HeartRateZoneInfoFeature>
    
    // MARK: - View
    
    // No own NavigationView — the presenter provides the navigation context: a
    // NavigationStack around the sheet during a workout, and the Settings
    // NavigationStack when pushed from "Strefy tętna i punkty".
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(store.zonesToDisplay) { zone in
                    heartRateZoneCell(for: zone)
                }
            }
            .padding()
        }
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            send(.viewDidAppear)
        }
    }
    
    // MARK: - Computed Properties
    
    private var navigationTitle: String {
        switch store.displayMode {
        case .allZones:
            return "Heart Rate Zones"
        case .singleZone(let zone):
            return zone.title
        }
    }
    
    // MARK: - Private Views
    
    private func heartRateZoneCell(for zone: HeartRateZone) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Circle()
                    .fill(zone.color)
                    .frame(width: 20, height: 20)
                    .shadow(color: zone.color.opacity(0.3), radius: 2, x: 0, y: 1)
                HStack {
                    Text(zone.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                    Text(formatPercentageRange(zone.percentageRange))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                pointsBadge(for: zone)
            }
            heartRateZoneDescription(for: zone)
            
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(zone.color.opacity(0.3), lineWidth: 1)
        )
    }
    
    /// Effort points earned per minute in this zone (Myzone-style). Hidden for
    /// `resting` — it has no entry in the scoring table (rest earns nothing).
    @ViewBuilder
    private func pointsBadge(for zone: HeartRateZone) -> some View {
        if let perMinute = EffortPointsScoring.pointsPerMinute[zone] {
            HStack(spacing: 3) {
                Image(systemName: "bolt.fill")
                    .font(.caption2)
                    .foregroundStyle(.yellow)
                Text(pointsPerMinuteText(Int(perMinute)))
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundStyle(zone.color)
        }
    }

    private func heartRateZoneDescription(for zone: HeartRateZone) -> some View {
        DisclosureGroup(zone.description,
            isExpanded: Binding(
                get: { store.selectedZone == zone && store.descriptionIsExpanded },
                set: { isExpanded in
                    if isExpanded {
                        send(.selectedZoneDescription(zone))
                    } else {
                        send(.selectedZoneDescription(nil))
                    }
                }
            )
        ) {
            Text(zone.detailedDescription)
                .font(.footnote)
                .multilineTextAlignment(.leading)
                .padding(.top, 4)
        }
        .foregroundStyle(.primary)
    }
    
    // MARK: - Helper Methods
    
    private func formatPercentageRange(_ range: ClosedRange<Double>) -> String {
        let lowerBound = Int(range.lowerBound * 100)
        let upperBound = Int(range.upperBound * 100)
        return "\(lowerBound)% - \(upperBound)% HR max"
    }

    private func pointsPerMinuteText(_ points: Int) -> String {
        String(localized: "\(points) pkt/min", bundle: .main)
    }
}
