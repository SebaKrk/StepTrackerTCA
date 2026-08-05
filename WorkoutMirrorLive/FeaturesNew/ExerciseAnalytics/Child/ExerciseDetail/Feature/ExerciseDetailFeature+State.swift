//
//  ExerciseDetailFeature+State.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 24/04/2026.
//

import ComposableArchitecture
import Foundation
import SharedModels

extension ExerciseDetailFeature {

    @ObservableState
    struct State {

        // MARK: - Chart Points

        struct WeightProgressionPoint: Identifiable, Equatable, Hashable {
            let date: Date
            let weight: Double
            var id: Date { date }
        }

        struct WeeklyVolumePoint: Identifiable, Equatable, Hashable {
            let week: Date
            let volume: Double
            var id: Date { week }
        }

        struct HRSessionPoint: Identifiable, Equatable, Hashable {
            let date: Date
            let avgHR: Double
            var id: Date { date }
        }

        // MARK: - Properties

        let exerciseType: ExerciseType
        var logs: [ExerciseLog] = []

        /// Weekly volume points for the chart.
        /// Recomputed by the reducer on `.logsLoaded` using `@Dependency(\.calendar)`.
        var weeklyVolume: [WeeklyVolumePoint] = []

        // MARK: - Navigation

        /// Activity detail presented when user taps a history row.
        @Presents var activityDetail: ActivityDetailsFeature.State?

        /// Loading indicator when fetching HKWorkout for a tapped history row.
        var isLoadingActivity: Bool = false

        // MARK: - Send to Developer

        /// Confirmation alert shown before sharing the unrecognized-names report.
        @Presents var alert: AlertState<Action.Alert>?

        /// Temp-file handed to the share sheet once the user confirms the alert.
        var reportShareFile: ReportShareFile?

        struct ReportShareFile: Equatable, Identifiable {
            let url: URL
            var id: URL { url }
        }

        // MARK: - Computed — Header

        var displayName: String { exerciseType.displayName }
        var category: MovementCategory { exerciseType.category }
        var count: Int { logs.count }

        var pr: Double? {
            logs.compactMap(\.actualWeight).max()
        }

        /// Whether this exercise uses weight (has any actualWeight recorded).
        var hasWeight: Bool {
            logs.contains { ($0.actualWeight ?? 0) > 0 }
        }

        var avgHR: Double? {
            let hrs = logs.compactMap(\.avgHeartRate)
            guard !hrs.isEmpty else { return nil }
            return hrs.reduce(0, +) / Double(hrs.count)
        }

        var maxHR: Double? {
            logs.compactMap(\.maxHeartRate).max()
        }

        // MARK: - Computed — Unrecognized Names

        /// Distinct raw OCR/AI names hiding in the unknown bucket with occurrence
        /// counts, most frequent first. Diagnostic input for extending the
        /// `ExerciseType` catalog — aggregates the same `logs` the screen already
        /// shows, so the numbers stay consistent with the session count.
        var unmatchedNameCounts: [(name: String, count: Int)] {
            Dictionary(grouping: logs.compactMap(\.unmatchedName)) { $0 }
                .map { (name: $0.key, count: $0.value.count) }
                .sorted { $0.count > $1.count }
        }

        /// Plain-text report for the "send to developer" share — metadata header
        /// (app version + catalog version, so the harvest is attributable to a
        /// concrete catalog state) followed by "name<TAB>count" lines. Contains
        /// no workout data beyond the raw exercise names.
        var unrecognizedNamesReport: String {
            let info = Bundle.main.infoDictionary
            let version = info?["CFBundleShortVersionString"] as? String ?? "?"
            let build = info?["CFBundleVersion"] as? String ?? "?"
            let lines = unmatchedNameCounts.map { "\($0.name)\t\($0.count)" }
            return """
            # MyFitnessJournal — unrecognized exercise names
            # app \(version) (\(build)) · catalog v\(ExerciseType.catalogVersion)
            \(lines.joined(separator: "\n"))
            """
        }

        // MARK: - Computed — Weight Progression Chart

        var weightProgression: [WeightProgressionPoint] {
            logs.compactMap { log in
                guard let w = log.actualWeight else { return nil }
                return WeightProgressionPoint(date: log.date, weight: w)
            }
            .sorted { $0.date < $1.date }
        }

        // MARK: - Computed — HR per Session Chart

        var hrPerSession: [HRSessionPoint] {
            logs.compactMap { log in
                guard let hr = log.avgHeartRate else { return nil }
                return HRSessionPoint(date: log.date, avgHR: hr)
            }
            .sorted { $0.date < $1.date }
        }
    }
}

