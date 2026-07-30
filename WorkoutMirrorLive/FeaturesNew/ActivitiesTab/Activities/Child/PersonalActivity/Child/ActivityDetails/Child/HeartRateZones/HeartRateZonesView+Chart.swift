//
//  HeartRateZonesView+Chart.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 27/06/2026.
//
//  Per-minute HR range bar chart z gradient color per HeartRateZone — wzorowane 1:1 na
//  `ClassHistoryDetailView.athleteCardChart` z GymRoom (IPAD-00091).
//
//  `send(.X)` jest dostępne w extension'ie bo `@ViewAction(for: HeartRateZonesFeature.self)`
//  jest na głównym `struct HeartRateZonesView`. Macro generuje send method na typie, więc
//  wszystkie extension'y dziedziczą API "za darmo".

import Charts
import ComposableArchitecture
import SharedModels
import SwiftUI

extension HeartRateZonesView {

    // MARK: - Section (renderowana NAD rozwijalnym zoneDistributionSection)

    /// Range bar chart per minuta — yStart=minHR, yEnd=maxHR. Bar pokolorowany gradientem od
    /// strefy minHR (dół) do strefy maxHR (góra). Renderowany tylko gdy są dane HR
    /// (`store.hrMinuteRanges` non-empty).
    @ViewBuilder
    func hrRangeChartSection() -> some View {
        if !store.hrMinuteRanges.isEmpty {
            GroupBox {
                hrRangeChart
            } label: {
                hrRangeChartLabel
            }
            .styledGroupBox()
        }
    }

    /// Header label tej sekcji — caption + secondary, wzorem `MetricCardLabel`.
    private var hrRangeChartLabel: some View {
        Label(hrRangeChartTitle, systemImage: "chart.xyaxis.line")
            .font(.caption)
            .foregroundColor(.secondary)
    }

    // MARK: - Chart (rendering delegated to the shared HRMinuteRangeChart)

    /// Rendering moved verbatim to `HRMinuteRangeChart` (UI/HeartRate) so the
    /// Summary screen charts identically. This extension only maps store → values.
    private var hrRangeChart: some View {
        HRMinuteRangeChart(
            ranges: store.hrMinuteRanges,
            userMaxHeartRate: Int(store.maxHeartRate),
            selectedMinute: minuteSelectionBinding
        )
    }

    /// Custom binding routujący scrub przez TCA action. Wzorem `athleteSelectionBinding` z GymRoom.
    private var minuteSelectionBinding: Binding<Date?> {
        Binding(
            get: { store.selectedMinute },
            set: { send(.minuteSelected($0)) }
        )
    }

    // MARK: - Localized strings

    private var hrRangeChartTitle: String {
        String(localized: "Tętno minuta po minucie")
    }
}
