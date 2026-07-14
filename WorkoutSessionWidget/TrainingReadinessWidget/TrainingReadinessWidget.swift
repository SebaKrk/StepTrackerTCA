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
    
    private let userDefaults = UserDefaults(suiteName: "group.com.ss.lf.WorkoutMirrorLive")
    private let key = "widget_readiness_data"
    
    func placeholder(in context: Context) -> TrainingReadinessEntry {
        TrainingReadinessEntry(date: Date(), result: .preview)
    }

    func getSnapshot(in context: Context, completion: @escaping (TrainingReadinessEntry) -> ()) {
        let result = loadReadinessResult() ?? .preview
        completion(TrainingReadinessEntry(date: Date(), result: result))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TrainingReadinessEntry>) -> ()) {
        let loadedResult = loadReadinessResult()
        
        // Use loaded result, or fallback to preview ONLY if we are in a preview context
        let finalResult: TrainingReadinessResult? = loadedResult ?? (context.isPreview ? .preview : nil)
        
        let entry = TrainingReadinessEntry(date: Date(), result: finalResult)
        let timeline = Timeline(entries: [entry], policy: .never)
        completion(timeline)
    }
    
    private func loadReadinessResult() -> TrainingReadinessResult? {
        guard let data = userDefaults?.data(forKey: key) else {
            return nil
        }
        
        guard let widgetData = try? JSONDecoder().decode(WidgetReadinessData.self, from: data) else {
            return nil
        }
        
        // Convert DTO to TrainingReadinessResult
        return TrainingReadinessResult(
            overallScore: widgetData.overallScore,
            components: TrainingReadinessComponents(
                restingHeartRate: widgetData.rhrValue.map {
                    TrainingComponentScore(score: 0, currentValue: $0, baselineValue: nil, unit: "bpm", minScore: -15, maxScore: 15)
                },
                heartRateVariability: widgetData.hrvValue.map {
                    TrainingComponentScore(score: 0, currentValue: $0, baselineValue: nil, unit: "ms", minScore: -15, maxScore: 15)
                },
                sleepQuality: widgetData.sleepValue.map {
                    TrainingComponentScore(score: 0, currentValue: $0, baselineValue: nil, unit: "hours", minScore: -10, maxScore: 15)
                },
                previousDayLoad: widgetData.activityValue.map {
                    TrainingComponentScore(score: 0, currentValue: $0, baselineValue: nil, unit: "kcal", minScore: -10, maxScore: 5)
                }
            ),
            isReliable: true
        )
    }
}

struct TrainingReadinessEntry: TimelineEntry {
    let date: Date
    let result: TrainingReadinessResult?
}

struct TrainingReadinessWidgetEntryView : View {
    var entry: TrainingReadinessProvider.Entry

    // MARK: - Environment
    @Environment(\.widgetFamily) var family

    var body: some View {
        Group {
            if let result = entry.result {
                switch family {
                case .systemSmall:
                    smallView(for: result)
                case .systemMedium:
                    mediumView(for: result)
                default:
                    smallView(for: result)
                }
            } else {
                noDataView
            }
        }
        .containerBackground(for: .widget) {
            Color(UIColor.systemBackground)
        }
    }
    
    // MARK: - Views
    
    var noDataView: some View {
        ZStack {
            // Blurred placeholder background
            VStack(spacing: 2) {
                smallHeader
                readinessChart(diameter: nil, score: 0, showScore: false)
                Text("-")
            }
            .blur(radius: 6)
            
            // Message
            VStack(spacing: 4) {
                Image(systemName: "chart.bar.xaxis")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
                Text("No Data")
                    .font(.caption.bold())
                Text("Open App")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    func smallView(for result: TrainingReadinessResult) -> some View {
        VStack(spacing: 2) {
            smallHeader
            readinessChart(diameter: nil, score: result.overallScore, showScore: true)
            statusText(for: result)
        }
    }
    
    func mediumView(for result: TrainingReadinessResult) -> some View {
        VStack(spacing: 12) {
            mediumHeader(date: entry.date)
            HStack(spacing: 20) {
                VStack {
                    readinessChart(diameter: 100, score: result.overallScore, showScore: true)
                    Text(result.readinessLevel.title)
                        .font(.caption.bold())
                        .foregroundStyle(result.readinessLevel.color)
                }
                breakdownList(for: result)
            }
        }
    }
    
    // MARK: - Subviews
    
    var smallHeader: some View {
        HStack {
            Text("Training Readiness")
                .bold()
                .font(.caption2)
                .foregroundStyle(.secondary)
            Spacer()
        }
    }
    
    func mediumHeader(date: Date) -> some View {
        HStack {
            Text("TRAINING READINESS")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.secondary)
            
            Spacer()
            
            Text(date.formatted(date: .numeric, time: .omitted))
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.secondary)
        }
    }
    
    func breakdownList(for result: TrainingReadinessResult) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            if let rhr = result.components.restingHeartRate {
                componentRow(icon: "heart.fill", title: "RHR", value: String(format: "%.0f bpm", rhr.currentValue))
            }
            if let sleep = result.components.sleepQuality {
                componentRow(icon: "bed.double.fill", title: "Sleep", value: String(format: "%.1f h", sleep.currentValue))
            }
            if let hrv = result.components.heartRateVariability {
                componentRow(icon: "waveform.path.ecg", title: "HRV", value: String(format: "%.0f ms", hrv.currentValue))
            }
            if let act = result.components.previousDayLoad {
                componentRow(icon: "flame.fill", title: "Act.", value: String(format: "%.0f kcal", act.currentValue))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 4)
    }
    
    func statusText(for result: TrainingReadinessResult) -> some View {
        Text(result.readinessLevel.title)
            .font(.caption2.bold())
            .foregroundStyle(result.readinessLevel.color)
            .multilineTextAlignment(.center)
            .lineLimit(2)
            .fixedSize(horizontal: false, vertical: true)
    }
    
    func readinessChart(diameter: CGFloat?, score: Int, showScore: Bool) -> some View {
        ZStack {
            Chart {
                ForEach(generateBackgroundTrack()) { slice in
                    SectorMark(
                        angle: .value("Value", slice.value),
                        innerRadius: .ratio(0.55),
                        angularInset: 0
                    )
                    .cornerRadius(2)
                    .foregroundStyle(slice.color)
                }
            }
            .chartBackground { _ in Color.clear }
            
            Chart {
                ForEach(generateForegroundTrack()) { slice in
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
    
    func generateForegroundTrack() -> [ChartSlice] {
        segments.map { segment in
            let width = Double(segment.range.upperBound - segment.range.lowerBound)
            return ChartSlice(value: width, color: segment.color)
        }
    }
    
}

struct TrainingReadinessWidget: Widget {
    
    let kind: String = "TrainingReadinessWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TrainingReadinessProvider()) { entry in
            TrainingReadinessWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Training Readiness")
        .description("Check your daily training readiness.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Preview Mock

extension TrainingReadinessResult {
    static var preview: TrainingReadinessResult {
        TrainingReadinessResult(
            overallScore: 11,
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
