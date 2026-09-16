//
//  HeartRateZonesView.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 16/07/2026.
//

import ComposableArchitecture
import SharedModels
import SwiftUI

/// HR chart + zones sections of the Activity Details screen. The per-minute
/// range chart lives in `HeartRateZonesView+Chart.swift`.
@ViewAction(for: HeartRateZonesFeature.self)
struct HeartRateZonesView: View {

    // MARK: - Properties

    @Bindable var store: StoreOf<HeartRateZonesFeature>

    // MARK: - Body

    var body: some View {
        // Group, not VStack — both sections land directly in the parent's VStack,
        // so a hidden section contributes no phantom spacing slot.
        Group {
            hrRangeChartSection()
            if let distribution = store.zoneDistribution {
                zoneDistributionSection(distribution)
            }
        }
    }

    // MARK: - Zone Distribution

    private func zoneDistributionSection(_ distribution: [HeartRateZone: TimeInterval]) -> some View {
        GroupBox {
            heartRateZone(distribution)
        } label: {
            zoneSectionHeader
        }
        .backgroundStyle(.clear)
        .background(sectionBackground)
    }

    /// HR-zones section title + effort points badge. Static — the time↔points
    /// toggle lives on the expanded rows themselves (more discoverable there).
    private var zoneSectionHeader: some View {
        HStack {
            Label(zonesTitle, systemImage: "heart.text.square")
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            if let points = store.effortScore?.points {
                zonePointsBadge(points)
            }
        }
    }

    /// Frozen effort points (Myzone-style), shown in the HR-zones section header —
    /// the points are earned FROM time in zones, so they live next to that title.
    private func zonePointsBadge(_ points: Int) -> some View {
        HStack(spacing: 3) {
            Image(systemName: "bolt.fill")
                .font(.caption2)
                .foregroundStyle(.yellow)
            Text("\(points)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.primary)
            Text(pointsUnit)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func heartRateZone(_ distribution: [HeartRateZone: TimeInterval]) -> some View {
        DisclosureGroup(isExpanded: Binding(
            get: { store.isExpandZone },
            set: { isExpanded in
                send(.zoneDisclosureToggled(isExpanded))
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
                .contentShape(Rectangle())
                .onTapGesture {
                    // Tap the expanded rows to flip time ↔ points. No-op without a
                    // stored score (pre-feature workouts show time only).
                    if store.effortScore != nil { send(.zonePointsToggled) }
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
        Text(primaryZoneTitle + ":")
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
        Text(timeInZoneTitle + ":")
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
            Text(store.showZonePoints ? zonePointsText(for: zone) : formatDuration(duration))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    /// Points a zone contributed, from the FROZEN `secondsByZone` in the saved
    /// score. Uses `pointsByZone` (largest-remainder) so the rows GUARANTEED sum to
    /// the total badge — computing per-zone independently would let them drift.
    private func zonePointsText(for zone: HeartRateZone) -> String {
        let breakdown = store.effortScore.map { EffortPointsScoring.pointsByZone(from: $0.secondsByZone) } ?? [:]
        let points = breakdown[zone] ?? 0
        return String(localized: "\(points) pts", bundle: .main)
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

    // MARK: - Implementation

    private var sectionBackground: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .stroke(.gray.opacity(0.5), lineWidth: 0.5)
            .fill(Color(.secondarySystemBackground).gradient.opacity(0.5))
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return "\(minutes)m \(secs)s"
    }

    private var zonesTitle: String {
        String(localized: "Heart Rate Zones", bundle: .main)
    }

    private var primaryZoneTitle: String {
        String(localized: "Primary Zone", bundle: .main)
    }

    private var timeInZoneTitle: String {
        String(localized: "Time in zone", bundle: .main)
    }

    private var pointsUnit: String {
        String(localized: "pts", bundle: .main)
    }
}
