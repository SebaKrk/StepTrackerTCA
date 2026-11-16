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
    
    private let userDefaults = UserDefaults(suiteName: "group.com.ss.WorkoutMirrorLive")
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

        // Hourly rather than `.never`: the widget cannot calculate anything, but
        // it can re-read what the app wrote while it was asleep. With `.never` a
        // score computed in the background reached the screen only if the reload
        // happened to get through.
        let nextReload = Date(timeIntervalSinceNow: 60 * 60)
        let timeline = Timeline(entries: [entry], policy: .after(nextReload))

        completion(timeline)
    }
    
    private func loadReadinessResult() -> TrainingReadinessResult? {
        guard let data = userDefaults?.data(forKey: key) else {
            return nil
        }
        
        guard let widgetData = try? JSONDecoder().decode(WidgetReadinessData.self, from: data) else {
            return nil
        }
        
        // Convert DTO to TrainingReadinessResult. The widget stores measured
        // values only, so component scores come back as 0 — it renders the
        // numbers and the overall ring, never per-component status.
        let components = TrainingReadinessComponents(
            restingHeartRate: component(.rhr, value: widgetData.rhrValue),
            heartRateVariability: component(.hrv, value: widgetData.hrvValue),
            sleepQuality: component(.sleep, value: widgetData.sleepValue),
            previousDayLoad: component(.activity, value: widgetData.activityValue)
        )

        return TrainingReadinessResult(
            overallScore: widgetData.overallScore,
            components: components,
            calculatedAt: widgetData.calculatedAt,
            // Re-derived rather than assumed: hardcoding `true` let a score built
            // on two components look exactly like one built on four.
            isReliable: components.available.count >= TrainingReadinessResult.minimumReliableComponents
        )
    }

    /// Rebuilds one component from the stored value, taking its range from
    /// `HealthMetricType` so the widget cannot drift from the app.
    private func component(_ metric: HealthMetricType, value: Double?) -> TrainingComponentScore? {
        value.map {
            TrainingComponentScore(
                score: 0,
                currentValue: $0,
                baselineValue: nil,
                unit: metric.unit,
                minScore: metric.minScore,
                maxScore: metric.maxScore
            )
        }
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
                smallHeader(caveat: nil)
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
            smallHeader(caveat: caveat(for: result))
            readinessChart(diameter: nil, score: result.overallScore, showScore: true)
            statusText(for: result)
        }
    }

    func mediumView(for result: TrainingReadinessResult) -> some View {
        VStack(spacing: 12) {
            mediumHeader(for: result)
            HStack(spacing: 20) {
                VStack(spacing: 2) {
                    readinessChart(diameter: 100, score: result.overallScore, showScore: true)
                    Text(result.readinessLevel.title)
                        .font(.caption.bold())
                        .foregroundStyle(result.readinessLevel.color)
                    estimateMarker(for: result)
                }
                breakdownList(for: result)
            }
        }
    }
    
    // MARK: - Subviews
    
    func smallHeader(caveat: String?) -> some View {
        HStack(spacing: 4) {
            Text("Training Readiness")
                .bold()
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Spacer(minLength: 0)

            if let caveat {
                Text(caveat)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(Color.orange)
                    .lineLimit(1)
            }
        }
    }

    func mediumHeader(for result: TrainingReadinessResult) -> some View {
        HStack {
            Text("TRAINING READINESS")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.secondary)

            Spacer()

            // The score's own date, not the moment the timeline was built — the
            // widget keeps the last score through a morning that has none yet.
            Text(result.calculatedAt.formatted(date: .numeric, time: .omitted))
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(isFromToday(result) ? Color.secondary : Color.orange)
        }
    }

    func estimateMarker(for result: TrainingReadinessResult) -> some View {
        Group {
            if !result.isReliable {
                Text("estimated")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.secondary)
            }
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
    
    // MARK: - Provenance

    /// Whether the score on screen was calculated today.
    func isFromToday(_ result: TrainingReadinessResult) -> Bool {
        Calendar.current.isDateInToday(result.calculatedAt)
    }

    /// What the figure needs saying about it in the small family, if anything.
    ///
    /// A score from another day is wrong about today whatever built it, so it
    /// outranks the estimate caveat instead of sharing the one slot with it.
    func caveat(for result: TrainingReadinessResult) -> String? {
        guard isFromToday(result) else {
            return result.calculatedAt.formatted(.relative(presentation: .named))
        }

        // The same key the Watch marks an estimate with, rather than a second
        // string for one word.
        return result.isReliable ? nil : String(localized: "estimated")
    }

    // MARK: - Logic

    struct ReadinessSegment {
        let range: ClosedRange<Double>
        let color: Color

        /// How much of the ring this segment covers.
        var width: Double {
            range.upperBound - range.lowerBound
        }
    }

    /// Built from `ReadinessLevel` so the widget cannot drift from the app.
    var segments: [ReadinessSegment] {
        ReadinessLevel.allCases.map {
            ReadinessSegment(range: $0.chartRange, color: $0.color)
        }
    }
    
    struct ChartSlice: Identifiable {
        let id = UUID()
        let value: Double
        let color: Color
    }
    
    func generateBackgroundTrack() -> [ChartSlice] {
        segments.map { segment in
            ChartSlice(value: segment.width, color: segment.color.opacity(0.15))
        }
    }

    func generateForegroundTrack() -> [ChartSlice] {
        segments.map { segment in
            ChartSlice(value: segment.width, color: segment.color)
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
