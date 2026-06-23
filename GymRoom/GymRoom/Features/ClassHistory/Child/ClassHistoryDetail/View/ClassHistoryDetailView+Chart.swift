//
//  ClassHistoryDetailView+Chart.swift
//  GymRoom
//
//  Created by Sebastian Ściuba on 22/06/2026.
//

import Charts
import SharedModels
import SwiftUI

extension ClassHistoryDetailView {

    /// Range bar dla pojedynczej minuty — odcinek pionowy od `minHR` do `maxHR`.
    /// Wyszary'owany gdy w danym chart'cie jest selection i to NIE jest wybrany słupek.
    func createBarMark(_ range: HRMinuteRange, isSelected: Bool, style: some ShapeStyle) -> some ChartContent {
        BarMark(
            x: .value("Minute", range.minute, unit: .minute),
            yStart: .value("HR min", range.minHR),
            yEnd: .value("HR max", range.maxHR),
            width: .ratio(0.8)
        )
        .foregroundStyle(style)
        .opacity(isSelected ? 1.0 : 0.5)
        .cornerRadius(3)
    }

    /// Pionowa linia + annotation na wybranej minucie. Analog
    /// `HeartRateDetailsView+Chart.createRuleMark`. Annotation pozycjonowany
    /// bottomTrailing z `overflowResolution(.fit(to: .chart))` — nigdy nie wyleci
    /// poza obszar wykresu.
    func createRuleMark<Content: View>(
        with selectedDate: Date,
        @ViewBuilder annotationView: @escaping () -> Content
    ) -> some ChartContent {
        RuleMark(x: .value("Selected Minute", selectedDate, unit: .minute))
            .foregroundStyle(Color.secondary.opacity(0.3))
            .offset(y: -30)
            .annotation(
                position: .bottomTrailing,
                spacing: 4,
                overflowResolution: .init(x: .fit(to: .chart), y: .disabled)
            ) {
                annotationView()
            }
    }

}
