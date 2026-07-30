//
//  TrainingReadinessComponents.swift
//  SharedModels
//
//  Created by Sebastian Sciuba on 28/09/2025.
//

import Foundation

/// Contains individual component scores that contribute to overall training readiness.
///
/// `TrainingReadinessComponents` aggregates the various physiological and recovery
/// metrics used to calculate training readiness. Each component represents a different
/// aspect of the user's current state and readiness for physical activity.
///
/// ## Usage
/// ```swift
/// let components = TrainingReadinessComponents(
///     restingHeartRate: TrainingComponentScore(score: 10, currentValue: 52.0, baselineValue: 55.0, unit: "bpm"),
///     heartRateVariability: nil, // No HRV data available
///     sleepQuality: TrainingComponentScore(score: 5, currentValue: 7.5, baselineValue: 7.8, unit: "hours"),
///     previousDayLoad: TrainingComponentScore(score: -5, currentValue: 450.0, baselineValue: 320.0, unit: "kcal")
/// )
/// ```
///
/// ## Components
/// All components are optional to handle cases where specific data types are unavailable:
/// - **Resting Heart Rate**: Lower values typically indicate better recovery
/// - **Heart Rate Variability**: Higher values generally suggest better autonomic balance
/// - **Sleep Quality**: Duration and efficiency of sleep from the previous night
/// - **Previous Day Load**: Training load from the previous day affecting current readiness
public struct TrainingReadinessComponents: Sendable, Equatable {
    
    /// Resting heart rate component score.
    ///
    /// Represents the user's current resting heart rate compared to their baseline.
    /// Lower resting heart rate typically indicates better cardiovascular fitness and recovery.
    public let restingHeartRate: TrainingComponentScore?
    
    /// Heart rate variability component score.
    ///
    /// Measures the variation in time between heartbeats, indicating autonomic nervous system balance.
    /// Higher HRV generally suggests better recovery and readiness for training.
    public let heartRateVariability: TrainingComponentScore?
    
    /// Sleep quality component score.
    ///
    /// Evaluates sleep duration, efficiency, and quality from the previous night.
    /// Better sleep metrics contribute positively to training readiness.
    public let sleepQuality: TrainingComponentScore?
    
    /// Previous day training load component score.
    ///
    /// Assesses the impact of yesterday's training load on current readiness.
    /// Higher previous day loads may negatively impact current training readiness.
    public let previousDayLoad: TrainingComponentScore?
    
    /// Creates a new TrainingReadinessComponents instance.
    ///
    /// - Parameters:
    ///   - restingHeartRate: Optional resting heart rate component score
    ///   - heartRateVariability: Optional HRV component score
    ///   - sleepQuality: Optional sleep quality component score
    ///   - previousDayLoad: Optional previous day load component score
    public init(
        restingHeartRate: TrainingComponentScore?,
        heartRateVariability: TrainingComponentScore?,
        sleepQuality: TrainingComponentScore?,
        previousDayLoad: TrainingComponentScore?
    ) {
        self.restingHeartRate = restingHeartRate
        self.heartRateVariability = heartRateVariability
        self.sleepQuality = sleepQuality
        self.previousDayLoad = previousDayLoad
    }
    
}
