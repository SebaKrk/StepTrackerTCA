//
//  RouteDetailsView.swift
//  MyFitnessJournal
//
//  Created by Sebastian Ściuba on 06/08/2026.
//

import Charts
import ComposableArchitecture
import CoreLocation
import HealthHub
import HealthKit
import MapKit
import SharedModels
import SwiftUI

/// Route drill-in pushed from the "Route" tile of Activity Details. Same
/// visual language as the parent screen: `SimpleMetricCard` grid on top, a
/// static map card and a scrubbable per-minute pace chart below — the chart
/// selection lights up the matching point on the map (Apple Fitness-style).
struct RouteDetailsView: View {

    // MARK: - Properties

    @Bindable var store: StoreOf<RouteDetailsFeature>

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                statsGrid
                mapCard
                paceChartCard
                elevationChartCard
                runningDynamicsGrid
            }
        }
        .padding([.leading, .trailing], 8)
        .navigationTitle(routeTitle)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { store.send(.onAppear) }
    }

    // MARK: - Sections

    private var statsGrid: some View {
        LazyVGrid(columns: MetricCardGrid.twoColumns, spacing: 4) {
            SimpleMetricCard(
                title: String(localized: "Distance", bundle: .main),
                value: distanceValue,
                unit: "km",
                icon: "arrow.left.and.right"
            )
            SimpleMetricCard(
                title: String(localized: "Duration", bundle: .main),
                value: formattedDuration,
                unit: "",
                icon: "clock"
            )
            SimpleMetricCard(
                title: averageTitle,
                value: speedValue(store.averageSpeed),
                unit: speedUnit,
                icon: "speedometer"
            )
            SimpleMetricCard(
                title: bestTitle,
                value: speedValue(store.maxSpeed),
                unit: speedUnit,
                icon: activityIcon
            )
        }
    }

    /// Watch running dynamics — only the cards whose metric has samples, the
    /// whole section only when anything came back (runs without a Watch have
    /// nothing to show here).
    @ViewBuilder
    private var runningDynamicsGrid: some View {
        if let dynamics = store.runningDynamics, !dynamics.isEmpty {
            LazyVGrid(columns: MetricCardGrid.twoColumns, spacing: 4) {
                if let power = dynamics.averagePower {
                    SimpleMetricCard(
                        title: String(localized: "Running power", bundle: .main),
                        value: "\(Int(power.rounded()))",
                        unit: "W",
                        icon: "bolt.fill"
                    )
                }
                if let cadence = dynamics.cadence {
                    SimpleMetricCard(
                        title: String(localized: "Cadence", bundle: .main),
                        value: "\(Int(cadence.rounded()))",
                        unit: "spm",
                        icon: "metronome.fill"
                    )
                }
                if let stride = dynamics.strideLength {
                    SimpleMetricCard(
                        title: String(localized: "Stride length", bundle: .main),
                        value: stride.formatted(.number.precision(.fractionLength(2))),
                        unit: "m",
                        icon: "figure.walk.motion"
                    )
                }
                if let oscillation = dynamics.verticalOscillation {
                    SimpleMetricCard(
                        title: String(localized: "Vertical oscillation", bundle: .main),
                        value: oscillation.formatted(.number.precision(.fractionLength(1))),
                        unit: "cm",
                        icon: "arrow.up.and.down"
                    )
                }
                if let groundContact = dynamics.groundContactTime {
                    SimpleMetricCard(
                        title: String(localized: "Ground contact", bundle: .main),
                        value: "\(Int(groundContact.rounded()))",
                        unit: "ms",
                        icon: "shoeprints.fill"
                    )
                }
            }
        }
    }

    private var mapCard: some View {
        GroupBox {
            routeMap
                .disabled(true)
                .frame(height: 260)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        } label: {
            MetricCardLabel(title: routeTitle, icon: "figure.run")
        }
        .styledGroupBox()
    }

    private var paceChartCard: some View {
        GroupBox {
            VStack(spacing: 4) {
                paceChart
                zoneLegend
            }
        } label: {
            chartCardLabel(title: chartTitle, icon: activityIcon, unit: "km/h")
        }
        .styledGroupBox()
    }

    /// Chart card header: title on the left, axis unit on the right — keeps
    /// the unit off the plot area (an in-chart axis label squeezes it).
    private func chartCardLabel(title: String, icon: String, unit: String) -> some View {
        HStack {
            MetricCardLabel(title: title, icon: icon)
            Spacer()
            Text(verbatim: unit)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    /// Icon matching the workout type — a runner for runs, a bike for rides.
    private var activityIcon: String {
        store.isPaceBased ? "figure.run" : "figure.outdoor.cycle"
    }

    /// Color legend for the bars (height is explained by the card title and
    /// the Y axis; color is the non-obvious second encoding). Shows only the
    /// zones that actually occur in this workout; hidden without HR data.
    @ViewBuilder
    private var zoneLegend: some View {
        if !store.minuteZones.isEmpty {
            HStack(spacing: 10) {
                ForEach(zonesPresent) { zone in
                    HStack(spacing: 4) {
                        Circle()
                            .fill(zone.color)
                            .frame(width: 7, height: 7)
                        Text(zone.title)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 4)
        }
    }

    /// Zones occurring in this workout, in ascending intensity order.
    private var zonesPresent: [HeartRateZone] {
        let present = Set(store.minuteZones.values)
        return HeartRateZone.allCases.filter { present.contains($0) }
    }

    private var elevationChartCard: some View {
        GroupBox {
            elevationChart
        } label: {
            chartCardLabel(title: elevationTitle, icon: "mountain.2.fill", unit: "m")
        }
        .styledGroupBox()
    }

    // MARK: - Elevation chart (shared scrub with the pace chart)

    private var elevationChart: some View {
        Chart {
            if let selected = store.selectedPoint {
                elevationRuleMark(selected)
            }
            ForEach(store.pacePoints) { point in
                // yStart anchored to the domain floor — a plain `y:` AreaMark
                // fills down to 0, which with a 200 m+ domain bleeds far below
                // the plot area and out of the card.
                AreaMark(
                    x: .value("Minute", point.minute, unit: .minute),
                    yStart: .value("Base", elevationDomain.lowerBound),
                    yEnd: .value("Altitude", point.altitude)
                )
                .foregroundStyle(store.color.opacity(0.25))
                LineMark(
                    x: .value("Minute", point.minute, unit: .minute),
                    y: .value("Altitude", point.altitude)
                )
                .foregroundStyle(store.color)
            }
        }
        .chartYScale(domain: elevationDomain)
        .chartXSelection(value: $store.selectedMinute.animation(.easeInOut))
        .chartXAxis {
            AxisMarks(preset: .aligned, values: .automatic) { _ in
                AxisValueLabel()
            }
        }
        .frame(height: 140)
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
    }

    @ChartContentBuilder
    private func elevationRuleMark(_ point: RouteDetailsFeature.RouteMinutePoint) -> some ChartContent {
        RuleMark(x: .value("Selected Minute", point.minute, unit: .minute))
            .foregroundStyle(Color.secondary.opacity(0.3))
            .annotation(
                position: .top,
                spacing: 4,
                overflowResolution: .init(x: .fit(to: .chart), y: .disabled)
            ) {
                elevationAnnotation(point)
            }
    }

    private func elevationAnnotation(_ point: RouteDetailsFeature.RouteMinutePoint) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(point.minute, format: .dateTime.hour().minute())
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            HStack(spacing: 4) {
                Text("\(Int(point.altitude.rounded()))")
                    .font(.subheadline.bold().monospacedDigit())
                    .foregroundStyle(.primary)
                Text(verbatim: "m")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(.regularMaterial)
        )
    }

    // MARK: - Map

    private var routeMap: some View {
        Map {
            // Zone-colored route (Strava-style) once HR samples are aligned;
            // single readiness-colored polyline until then / without HR data.
            if let segments = store.zoneSegments, !segments.isEmpty {
                ForEach(segments) { segment in
                    MapPolyline(coordinates: segment.coordinates)
                        .stroke(segment.zone.color, lineWidth: 3)
                }
            } else {
                MapPolyline(coordinates: store.coordinates)
                    .stroke(store.color, lineWidth: 3)
            }
            if let start = store.coordinates.first {
                Annotation(startMarkerTitle, coordinate: start) {
                    routeMarker(color: .green)
                }
            }
            if let end = store.coordinates.last {
                Annotation(finishMarkerTitle, coordinate: end) {
                    routeMarker(color: .red)
                }
            }
            // Scrub highlight — follows the chart selection.
            if let selected = store.selectedPoint {
                Annotation("", coordinate: selected.coordinate) {
                    routeMarker(color: .blue)
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

    // MARK: - Pace chart (HRMinuteRangeChart sibling)

    private var paceChart: some View {
        Chart {
            if let selected = store.selectedPoint {
                selectionRuleMark(selected)
            }
            ForEach(store.pacePoints) { point in
                minuteBar(point)
            }
        }
        .chartXSelection(value: $store.selectedMinute.animation(.easeInOut))
        .chartXAxis {
            AxisMarks(preset: .aligned, values: .automatic) { _ in
                AxisValueLabel()
            }
        }
        .frame(height: 180)
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
    }

    private func minuteBar(_ point: RouteDetailsFeature.RouteMinutePoint) -> some ChartContent {
        BarMark(
            x: .value("Minute", point.minute, unit: .minute),
            y: .value("Speed", kilometersPerHour(point.speed)),
            width: .ratio(0.55)
        )
        // Effort = color, consistently with the zone-colored route; readiness
        // color is the no-HR-data fallback.
        .foregroundStyle(store.minuteZones[point.minute]?.color ?? store.color)
        .opacity(isSelected(point) ? 1.0 : 0.5)
        .cornerRadius(8)
    }

    @ChartContentBuilder
    private func selectionRuleMark(_ point: RouteDetailsFeature.RouteMinutePoint) -> some ChartContent {
        RuleMark(x: .value("Selected Minute", point.minute, unit: .minute))
            .foregroundStyle(Color.secondary.opacity(0.3))
            .annotation(
                position: .top,
                spacing: 4,
                overflowResolution: .init(x: .fit(to: .chart), y: .disabled)
            ) {
                paceAnnotation(point)
            }
    }

    private func paceAnnotation(_ point: RouteDetailsFeature.RouteMinutePoint) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(point.minute, format: .dateTime.hour().minute())
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            HStack(spacing: 4) {
                Text(speedValue(point.speed))
                    .font(.subheadline.bold().monospacedDigit())
                    .foregroundStyle(.primary)
                Text(speedUnit)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(.regularMaterial)
        )
    }

    private func isSelected(_ point: RouteDetailsFeature.RouteMinutePoint) -> Bool {
        guard let selected = store.selectedPoint else { return true }
        return selected.id == point.id
    }

    // MARK: - Formatting

    private var distanceValue: String {
        guard let meters = store.distance else { return "—" }
        return (meters / 1_000).formatted(.number.precision(.fractionLength(2)))
    }

    private var formattedDuration: String {
        Duration.seconds(store.workout.duration)
            .formatted(.time(pattern: .hourMinuteSecond))
    }

    private func kilometersPerHour(_ metersPerSecond: Double) -> Double {
        Measurement(value: metersPerSecond, unit: UnitSpeed.metersPerSecond)
            .converted(to: .kilometersPerHour)
            .value
    }

    private func speedValue(_ metersPerSecond: Double?) -> String {
        if store.isPaceBased {
            return PaceFormatter.text(fromMetersPerSecond: metersPerSecond)
        }
        guard let metersPerSecond, metersPerSecond > 0 else { return "—" }
        return kilometersPerHour(metersPerSecond)
            .formatted(.number.precision(.fractionLength(1)))
    }

    private var speedUnit: String {
        store.isPaceBased ? "/km" : "km/h"
    }

    private var averageTitle: String {
        store.isPaceBased
            ? String(localized: "Average pace", bundle: .main)
            : String(localized: "Average speed", bundle: .main)
    }

    private var bestTitle: String {
        store.isPaceBased
            ? String(localized: "Best pace", bundle: .main)
            : String(localized: "Maximum speed", bundle: .main)
    }

    private var chartTitle: String {
        store.isPaceBased
            ? String(localized: "Pace", bundle: .main)
            : String(localized: "Speed", bundle: .main)
    }

    private var elevationTitle: String {
        String(localized: "Elevation", bundle: .main)
    }

    /// Tight Y range around the actual altitudes (±2 m margin) — the automatic
    /// domain rounds to "nice" bounds and flattens small terrain differences.
    private var elevationDomain: ClosedRange<Double> {
        let altitudes = store.pacePoints.map(\.altitude)
        guard let min = altitudes.min(), let max = altitudes.max() else { return 0...1 }
        return (min - 2)...(max + 2)
    }

    private var routeTitle: String {
        String(localized: "Route", bundle: .main)
    }

    private var startMarkerTitle: String {
        String(localized: "Start", bundle: .main)
    }

    private var finishMarkerTitle: String {
        String(localized: "Finish", bundle: .main)
    }
}
