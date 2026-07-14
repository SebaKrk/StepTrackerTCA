//
//  MetricTypeDetails.swift
//  SharedModels
//
//  Created by Sebastian Sciuba on 04/01/2026.
//

import Foundation

/// Represents different workout performance metrics with their values and levels.
///
/// Used for navigation to metric detail views, providing all necessary data
/// to display metric information, scale visualization, and descriptions.
///
/// ## Usage
/// ```swift
/// let metric: MetricTypeDetails = .hrTSS(value: 73, level: .low)
///
/// switch metric {
/// case let .hrTSS(value, level):
///     print("Training load: \(value), recovery: \(level.recoveryEstimate)")
/// case let .intensity(value, level):
///     print("Intensity: \(value), zone: \(level.rawValue)")
/// // ...
/// }
/// ```
public enum MetricTypeDetails: Equatable, Sendable {
    
    /// Heart Rate Training Stress Score - training load based on HR intensity and duration.
    case hrTSS(value: Double, level: HRTSSLevel)
    
    /// Intensity Factor - workout effort relative to lactate threshold.
    case intensity(value: Double, level: IntensityFactorLevel)
    
    /// HR Recovery - heart rate drop 1 minute after workout (bpm).
    case hrRecovery(value: Int, level: HRRecoveryLevel)
    
    /// Recovery Demand - estimated recovery time based on training load and metrics.
    case recoveryDemand(value: RecoveryDemand, level: RecoveryDemandLevel)
    
    public var title: String {
        switch self {
        case .hrTSS:
            return String(localized: "hrTSS", bundle: .module)
        case .intensity:
            return String(localized: "Intensity Factor", bundle: .module)
        case .hrRecovery:
            return String(localized: "HR Recovery", bundle: .module)
        case .recoveryDemand:
            return String(localized: "Recovery Demand", bundle: .module)
        }
    }
    
    /// Detailed description explaining what this metric measures, including formula.
    public var metricDescription: String {
        switch self {
        case .hrTSS:
            return String(localized: """
            Heart Rate Training Stress Score (hrTSS) measures training load based on workout intensity and duration. It estimates how much recovery your body needs after a session.

            A score of 100 equals approximately one hour at lactate threshold intensity.

            Formula:
            hrTSS = Duration (hours) × Intensity Factor² × 100

            Where Intensity Factor = Average HR / Threshold HR
            Threshold HR = Max HR × 0.93
            """, bundle: .module)
            
        case .intensity:
            return String(localized: """
            Intensity Factor (IF) shows how hard you worked relative to your lactate threshold heart rate (LTHR).

            An IF of 1.0 means you exercised exactly at threshold intensity. Values above 1.0 indicate efforts harder than threshold pace.

            Formula:
            IF = Average HR / LTHR

            Where LTHR = Max HR × 0.85
            
            Typical values:
            • < 0.75: Recovery / Easy
            • 0.75–0.85: Aerobic / Endurance
            • 0.85–0.95: Tempo
            • 0.95–1.00: Threshold
            • > 1.00: VO2max / All-out
            """, bundle: .module)
            
        case .hrRecovery:
            return String(localized: """
            HR Recovery measures how many beats per minute (bpm) your heart rate drops in the first minute after stopping exercise.

            Faster recovery indicates better cardiovascular fitness and a more responsive autonomic nervous system.

            Formula:
            HR Recovery = Max HR during workout − HR after 1 minute

            Typical values:
            • < 12 bpm: Poor
            • 12–20 bpm: Average
            • 20–30 bpm: Good
            • 30–40 bpm: Very Good
            • > 40 bpm: Excellent
            """, bundle: .module)
            
        case .recoveryDemand:
            return String(localized: """
            Recovery Demand estimates how much rest you need before your next hard workout.

            It combines training load (hrTSS), heart rate recovery, and other factors to calculate optimal recovery time.

            Formula:
            Recovery (hours) = Base Recovery × HRR Modifier × HRV Modifier × Sleep Modifier

            Base Recovery is determined by hrTSS:
            • < 30: 12 hours
            • 30–50: 18 hours
            • 50–80: 28 hours
            • 80–120: 42 hours
            • 120–160: 56 hours
            • > 160: 72 hours

            Modifiers adjust based on your recovery metrics (better HR Recovery = faster recovery time).
            """, bundle: .module)
        }
    }
}
