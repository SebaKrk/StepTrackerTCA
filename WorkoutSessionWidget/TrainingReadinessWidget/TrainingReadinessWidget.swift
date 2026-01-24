//
//  TrainingReadinessWidget.swift
//  WorkoutSessionWidget
//
//  Created by Sebastian Sciuba on 24/01/2026.
//

import WidgetKit
import SwiftUI
import SharedModels
import Charts

struct TrainingReadinessProvider: TimelineProvider {
    func placeholder(in context: Context) -> TrainingReadinessEntry {
        TrainingReadinessEntry(date: Date(), result: .preview)
    }

    func getSnapshot(in context: Context, completion: @escaping (TrainingReadinessEntry) -> ()) {
        let entry = TrainingReadinessEntry(date: Date(), result: .preview)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TrainingReadinessEntry>) -> ()) {
        // Hardcoded timeline for now
        let entry = TrainingReadinessEntry(date: Date(), result: .preview)
        let timeline = Timeline(entries: [entry], policy: .never)
        completion(timeline)
    }
}

struct TrainingReadinessEntry: TimelineEntry {
    let date: Date
    let result: TrainingReadinessResult
}

struct TrainingReadinessWidgetEntryView : View {
    var entry: TrainingReadinessProvider.Entry

    // MARK: - Environment
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            smallView
        case .systemMedium:
            mediumView
        default:
            smallView
        }
    }
    
    // MARK: - Views
    
    var smallView: some View {
        VStack(spacing: 2) {
            smallHeader
            
            readinessChart(diameter: nil, score: entry.result.overallScore, showScore: true)
            
            statusText
        }
        .containerBackground(for: .widget) {
            Color(UIColor.systemBackground)
        }
    }
    
    var mediumView: some View {
        VStack(spacing: 12) {
            mediumHeader
            
            HStack(spacing: 20) {
                VStack {
                    readinessChart(diameter: 100, score: entry.result.overallScore, showScore: true)
                    
                    Text(entry.result.readinessLevel.title)
                        .font(.caption.bold())
                        .foregroundStyle(entry.result.readinessLevel.color)
                }
                
                breakdownList
            }
        }
        .containerBackground(for: .widget) {
            Color(UIColor.systemBackground)
        }
    }
    
    // MARK: - Subviews
    
    var smallHeader: some View {
        HStack {
            Text("Gotowość treningowa")
                .bold()
                .font(.caption2)
                .foregroundStyle(.secondary)
            Spacer()
        }
    }
    
    var mediumHeader: some View {
        HStack {
            Text("GOTOWOŚĆ TRENINGOWA")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.secondary)
            
            Spacer()
            
            Text(entry.date.formatted(date: .numeric, time: .omitted))
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.secondary)
        }
    }
    
    var breakdownList: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let rhr = entry.result.components.restingHeartRate {
                componentRow(icon: "heart.fill", title: "RHR", value: "\(Int(rhr.currentValue)) bpm")
            }
            if let sleep = entry.result.components.sleepQuality {
                componentRow(icon: "bed.double.fill", title: "Sen", value: "\(Int(sleep.currentValue)) h")
            }
            if let hrv = entry.result.components.heartRateVariability {
                componentRow(icon: "waveform.path.ecg", title: "HRV", value: "\(Int(hrv.currentValue)) ms")
            }
            if let act = entry.result.components.previousDayLoad {
                componentRow(icon: "flame.fill", title: "Akt.", value: "\(Int(act.currentValue)) kcal")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 4)
    }
    
    var statusText: some View {
        Text(entry.result.readinessLevel.title)
            .font(.caption2.bold())
            .foregroundStyle(entry.result.readinessLevel.color)
            .multilineTextAlignment(.center)
            .lineLimit(2)
            .fixedSize(horizontal: false, vertical: true)
    }
    
    func readinessChart(diameter: CGFloat?, score: Int, showScore: Bool) -> some View {
        ZStack {
            // Background
            Chart {
                ForEach(generateBackgroundTrack()) { slice in
                    SectorMark(
                        angle: .value("Value", slice.value),
                        innerRadius: .ratio(0.55),
                        angularInset: 0
                    )
                    .foregroundStyle(slice.color)
                }
            }
            .chartBackground { _ in Color.clear }
            
            // Foreground
            Chart {
                ForEach(generateForegroundSlices(for: score)) { slice in
                    SectorMark(
                        angle: .value("Value", slice.value),
                        innerRadius: .ratio(0.62),
                        outerRadius: .inset(4),
                        angularInset: 0.8
                    )
                    .cornerRadius(4)
                    .foregroundStyle(slice.color)
                }
            }
            .chartBackground { _ in Color.clear }
            
            if showScore {
                Text("\(score)")
                    .font(.system(size: diameter != nil ? 32 : 30, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
            }
        }
        .frame(width: diameter, height: diameter)
    }
    
    func componentRow(icon: String, title: String, value: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
    
    // MARK: - Logic
    
    struct ReadinessSegment {
        let range: ClosedRange<Int>
        let color: Color
    }
    
    let segments: [ReadinessSegment] = [
        ReadinessSegment(range: 0...40, color: .red),
        ReadinessSegment(range: 40...55, color: .orange),
        ReadinessSegment(range: 55...70, color: .yellow),
        ReadinessSegment(range: 70...85, color: .mint),
        ReadinessSegment(range: 85...100, color: .green)
    ]
    
    struct ChartSlice: Identifiable {
        let id = UUID()
        let value: Double
        let color: Color
    }
    
    func generateBackgroundTrack() -> [ChartSlice] {
        segments.map { segment in
            let width = Double(segment.range.upperBound - segment.range.lowerBound)
            return ChartSlice(value: width, color: segment.color.opacity(0.15))
        }
    }
    
    func generateForegroundSlices(for score: Int) -> [ChartSlice] {
        var slices: [ChartSlice] = []
        
        for segment in segments {
            let start = segment.range.lowerBound
            let end = segment.range.upperBound
            
            if score >= end {
                let width = Double(end - start)
                slices.append(ChartSlice(value: width, color: segment.color))
            } else if score > start {
                let filledPortion = Double(score - start)
                slices.append(ChartSlice(value: filledPortion, color: segment.color))
            }
        }
        return slices
    }
    
}

struct TrainingReadinessWidget: Widget {
    
    let kind: String = "TrainingReadinessWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TrainingReadinessProvider()) { entry in
            TrainingReadinessWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Gotowość Treningowa")
        .description("Sprawdź swoją dzienną gotowość do treningu.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Preview Mock

extension TrainingReadinessResult {
    static var preview: TrainingReadinessResult {
        TrainingReadinessResult(
            overallScore: 97,
            components: TrainingReadinessComponents(
                restingHeartRate: TrainingComponentScore(
                    score: 10,
                    currentValue: 50,
                    baselineValue: 55,
                    unit: "bpm",
                    minScore: -15,
                    maxScore: 15
                ),
                heartRateVariability: TrainingComponentScore(
                    score: 10,
                    currentValue: 82,
                    baselineValue: 70,
                    unit: "ms",
                    minScore: -15,
                    maxScore: 15
                ),
                sleepQuality: TrainingComponentScore(
                    score: 10,
                    currentValue: 7.5,
                    baselineValue: 8.0,
                    unit: "hours",
                    minScore: -10,
                    maxScore: 15
                ),
                previousDayLoad: TrainingComponentScore(
                    score: 5,
                    currentValue: 450,
                    baselineValue: 300,
                    unit: "kcal",
                    minScore: -10,
                    maxScore: 5
                )
            ),
            isReliable: true
        )
    }
}

#Preview(as: .systemSmall) {
    TrainingReadinessWidget()
} timeline: {
    TrainingReadinessEntry(date: .now, result: .preview)
}

#Preview(as: .systemMedium) {
    TrainingReadinessWidget()
} timeline: {
    TrainingReadinessEntry(date: .now, result: .preview)
}
