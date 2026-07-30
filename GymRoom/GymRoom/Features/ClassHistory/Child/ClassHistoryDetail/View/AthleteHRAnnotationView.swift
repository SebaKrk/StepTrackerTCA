//
//  AthleteHRAnnotationView.swift
//  GymRoom
//
//  Created by Sebastian Ściuba on 22/06/2026.
//

import SharedModels
import SwiftUI

/// Annotation chart'u po scrubie/taple — pokazuje czas + range BPM
/// wybranej minuty. Analog `ChartHRAnnotationView` ze StepTrackerTCA,
/// dostosowany do `HRMinuteRange` (Int zamiast Double).
struct AthleteHRAnnotationView: View {

    let range: HRMinuteRange
    let athleteColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            timeLabel
            bpmLabel
        }
        .padding(8)
        .background(annotationBackground)
    }

    // MARK: - Subviews (JAK)

    private var timeLabel: some View {
        Text(range.minute, format: timeFormat)
            .font(.caption2)
            .foregroundStyle(.secondary)
    }

    private var bpmLabel: some View {
        HStack(spacing: 4) {
            Image(systemName: "heart.fill")
                .foregroundStyle(athleteColor)
            Text("\(range.minHR)–\(range.maxHR)")
                .font(.caption.monospacedDigit().weight(.semibold))
            Text("BPM")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private var annotationBackground: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(.background)
            .shadow(radius: 2, y: 1)
    }

    private var timeFormat: Date.FormatStyle {
        .dateTime.hour().minute()
    }
}
