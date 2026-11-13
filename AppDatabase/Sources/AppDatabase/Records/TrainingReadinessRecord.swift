//
//  TrainingReadinessRecord.swift
//  AppDatabase
//
//  Created by Sebastian Sciuba on 08/11/2026.
//

import Foundation
import SharedModels
import SQLiteData

// MARK: - Record

/// SQLite record for one day's training readiness score.
///
/// The primary key is the readiness day as a calendar date (`yyyy-MM-dd`) with
/// `ON CONFLICT REPLACE`, so recalculating a day simply overwrites it and there
/// is no separate upsert path to get wrong. A date rather than a stored instant:
/// an instant carries a time zone offset and would split one local day into two
/// rows once the user travels. See `ReadinessDayKey`.
///
/// Not `CloudKitSyncable` on purpose: every row is derived from HealthKit and can
/// be recomputed on a new device, so it is a local cache of history rather than
/// user-authored data.
///
/// Storage strategy: flat scalar columns. Each component contributes its score,
/// measured value and baseline; all are nullable because a component can be
/// missing on any given day.
@Table
public struct TrainingReadinessRecord: Identifiable, Sendable {

    // MARK: - Properties

    /// The day this score belongs to, as `yyyy-MM-dd`.
    public var id: String

    /// Overall readiness score from 0 to 100.
    public var overallScore: Int

    /// Version of the scoring rules that produced this row.
    ///
    /// Rows written by different versions are not comparable; a trend chart has
    /// to say so rather than draw a step that the body never took.
    public var algorithmVersion: Int

    /// Whether enough components were available to trust the score.
    public var isReliable: Bool

    /// What anchored the day: a recorded sleep session, or the clock fallback.
    public var anchor: String

    /// When the user woke up, or the end of the fallback window.
    public var wakeTime: Date

    /// Resting heart rate contribution, in points.
    public var restingHeartRateScore: Int?

    /// Measured resting heart rate, in bpm.
    public var restingHeartRateValue: Double?

    /// Baseline resting heart rate it was compared against, in bpm.
    public var restingHeartRateBaseline: Double?

    /// Heart rate variability contribution, in points.
    public var hrvScore: Int?

    /// Measured heart rate variability, in milliseconds.
    public var hrvValue: Double?

    /// Baseline heart rate variability it was compared against, in milliseconds.
    public var hrvBaseline: Double?

    /// Sleep contribution, in points.
    public var sleepScore: Int?

    /// Measured sleep duration, in hours.
    public var sleepValue: Double?

    /// Baseline sleep duration it was compared against, in hours.
    public var sleepBaseline: Double?

    /// Previous day load contribution, in points.
    public var loadScore: Int?

    /// Measured active energy for the previous day, in kcal.
    public var loadValue: Double?

    /// Baseline active energy it was compared against, in kcal.
    public var loadBaseline: Double?

    /// When this row was last written.
    public var calculatedAt: Date

    // MARK: - Lifecycle

    /// Creates a readiness record.
    ///
    /// - Parameters:
    ///   - id: The readiness day as `yyyy-MM-dd`
    ///   - overallScore: Overall score from 0 to 100
    ///   - algorithmVersion: Version of the rules that produced it
    ///   - isReliable: Whether enough components were available
    ///   - anchor: What anchored the day
    ///   - wakeTime: When the user woke up
    ///   - restingHeartRateScore: Resting heart rate contribution
    ///   - restingHeartRateValue: Measured resting heart rate
    ///   - restingHeartRateBaseline: Resting heart rate baseline
    ///   - hrvScore: Heart rate variability contribution
    ///   - hrvValue: Measured heart rate variability
    ///   - hrvBaseline: Heart rate variability baseline
    ///   - sleepScore: Sleep contribution
    ///   - sleepValue: Measured sleep duration
    ///   - sleepBaseline: Sleep baseline
    ///   - loadScore: Previous day load contribution
    ///   - loadValue: Measured active energy
    ///   - loadBaseline: Active energy baseline
    ///   - calculatedAt: When the row was written
    public init(
        id: String,
        overallScore: Int,
        algorithmVersion: Int,
        isReliable: Bool,
        anchor: String,
        wakeTime: Date,
        restingHeartRateScore: Int? = nil,
        restingHeartRateValue: Double? = nil,
        restingHeartRateBaseline: Double? = nil,
        hrvScore: Int? = nil,
        hrvValue: Double? = nil,
        hrvBaseline: Double? = nil,
        sleepScore: Int? = nil,
        sleepValue: Double? = nil,
        sleepBaseline: Double? = nil,
        loadScore: Int? = nil,
        loadValue: Double? = nil,
        loadBaseline: Double? = nil,
        calculatedAt: Date
    ) {
        self.id = id
        self.overallScore = overallScore
        self.algorithmVersion = algorithmVersion
        self.isReliable = isReliable
        self.anchor = anchor
        self.wakeTime = wakeTime
        self.restingHeartRateScore = restingHeartRateScore
        self.restingHeartRateValue = restingHeartRateValue
        self.restingHeartRateBaseline = restingHeartRateBaseline
        self.hrvScore = hrvScore
        self.hrvValue = hrvValue
        self.hrvBaseline = hrvBaseline
        self.sleepScore = sleepScore
        self.sleepValue = sleepValue
        self.sleepBaseline = sleepBaseline
        self.loadScore = loadScore
        self.loadValue = loadValue
        self.loadBaseline = loadBaseline
        self.calculatedAt = calculatedAt
    }
}
