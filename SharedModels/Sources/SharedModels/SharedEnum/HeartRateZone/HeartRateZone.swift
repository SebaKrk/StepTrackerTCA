//
//  HeartRateZone.swift
//  SharedModels
//
//  Created by Sebastian Sciuba on 21/09/2025.
//

import SwiftUI

public enum HeartRateZone: String, CaseIterable, Identifiable, Sendable, Codable {
    
    case resting    // 0-50% HR max
    case recovery   // 50-60% HR max
    case fatBurning // 60-70% HR max
    case aerobic    // 70-80% HR max
    case threshold  // 80-90% HR max
    case anaerobic  // 90-100% HR max
    
    public var id: String { rawValue }
    
    /// Title key for localization
    public var title: String {
        switch self {
        case .resting: return String(localized: "Resting", bundle: .module)
        case .recovery: return String(localized: "Zone 1", bundle: .module)
        case .fatBurning: return String(localized: "Zone 2", bundle: .module)
        case .aerobic: return String(localized: "Zone 3", bundle: .module)
        case .threshold: return String(localized: "Zone 4", bundle: .module)
        case .anaerobic: return String(localized: "Zone 5", bundle: .module)
        }
    }
   
    public var color: Color {
        switch self {
        case .resting: return .gray
        case .recovery: return .blue
        case .fatBurning: return .green
        case .aerobic: return .yellow
        case .threshold: return .orange
        case .anaerobic: return .red
        }
    }
    
    public var description: String {
        switch self {
        case .resting:
            return String(localized: "Complete rest, minimal activity", bundle: .module)
        case .recovery:
            return String(localized: "Light activity, active recovery", bundle: .module)
        case .fatBurning:
            return String(localized: "Comfortable pace, fat burning", bundle: .module)
        case .aerobic:
            return String(localized: "Moderate effort, aerobic base", bundle: .module)
        case .threshold:
            return String(localized: "Hard effort, lactate threshold", bundle: .module)
        case .anaerobic:
            return String(localized: "Very hard, anaerobic power", bundle: .module)
        }
    }
    
    public var detailedDescription: String {
        switch self {
        case .resting:
            return String(localized: """
            The resting zone represents your baseline heart rate during complete rest, sleep, or minimal daily activities. This is your body's natural recovery state where cellular repair, hormone regulation, and nervous system restoration occur. Maintaining a healthy resting heart rate indicates good cardiovascular fitness and overall health. This zone is essential for stress recovery, sleep quality, and preparing your body for active periods.
            """, bundle: .module)
            
        case .recovery:
            return String(localized: """
            The recovery zone is the lightest level of physical activity, perfect for rest days or active recovery after intense training sessions. In this zone, your body effectively removes metabolic waste products, improves blood circulation, and supports muscle repair processes. By staying in this zone, you enhance flexibility, accelerate recovery, and prepare your body for future training challenges without additional physiological stress."
            """, bundle: .module)
            
            
        case .fatBurning:
            return String(localized: """
            The fat burning zone is the optimal range for those wanting to lose weight and improve metabolic efficiency. At this pace, your body primarily uses fatty acids as an energy source, leading to effective fat tissue burning. Long-duration training in this zone improves your body's ability to oxidize fats, increases insulin sensitivity, and builds a solid aerobic base without excessive fatigue.
            """, bundle: .module)
            
        case .aerobic:
            return String(localized: """
            The aerobic zone forms the foundation of endurance and is crucial for developing the cardiorespiratory system. Training in this range maximizes oxygen uptake, increases the number and size of mitochondria in muscles, and improves heart efficiency. By staying in this zone, you develop base endurance, increase stroke volume, and improve overall physical capacity, which forms the basis for all other forms of activity.
            """, bundle: .module)
            
        case .threshold:
            return String(localized: """
            The threshold zone is the intensity at which your body balances between aerobic and anaerobic metabolism. In this range, there's an equilibrium between lactate production and removal. Threshold training significantly improves your lactate threshold, increases critical power, and develops the ability to maintain high intensity for extended periods. This is a key zone for improving athletic performance and capacity in submaximal efforts.
            """, bundle: .module)
            
        case .anaerobic:
            return String(localized: """
            The anaerobic zone is the highest training intensity where your body works primarily in the anaerobic system. Significant lactate accumulation and rapid depletion of muscle glycogen occur here. Training in this zone develops anaerobic power, increases lactate buffering capacity, and improves the ability to perform very intense, short-duration efforts. This zone should be used sparingly due to high metabolic stress and long recovery times.
            """, bundle: .module)
        }
    }
    
    /// DISPLAY-ONLY range of the zone ("70-80%" labels, chart bands). The bounds
    /// deliberately overlap at the edges (0.7 belongs to both fatBurning and
    /// aerobic here), so this MUST NOT be used for classification — use
    /// `zone(forFraction:)`, which owns the boundary semantics.
    public var percentageRange: ClosedRange<Double> {
        switch self {
        case .resting: return 0.0...0.5
        case .recovery: return 0.5...0.6
        case .fatBurning: return 0.6...0.7
        case .aerobic: return 0.7...0.8
        case .threshold: return 0.8...0.9
        case .anaerobic: return 0.9...1.0
        }
    }

    /// Single source of truth for zone classification (fraction = bpm / maxHR).
    ///
    /// Half-open, lower-inclusive bounds: exactly 70% of maxHR is Zone 3 —
    /// a boundary belongs to the zone it opens. No upper bound on Zone 5:
    /// maxHR is a formula estimate and real peaks routinely exceed it
    /// (e.g. 198 bpm vs estimated 190 = 1.04) — supra-max effort is still
    /// maximal effort, never "resting".
    ///
    /// Classify the RAW fraction; truncate only for display (`Int(fraction * 100)`).
    /// Truncating first collapses the whole 70.0-70.9% band onto the 0.70
    /// boundary and lands it one zone lower than the raw value.
    public static func zone(forFraction fraction: Double) -> HeartRateZone {
        switch fraction {
        case ..<0.5: .resting
        case ..<0.6: .recovery
        case ..<0.7: .fatBurning
        case ..<0.8: .aerobic
        case ..<0.9: .threshold
        default:     .anaerobic
        }
    }

    /// Convenience over `zone(forFraction:)` for raw measured values.
    /// Owns the maxHR guard so call sites cannot forget it and feed a
    /// division by zero into the classifier (inf falls into the `default:`
    /// case and would silently read as maximal effort). Missing maxHR
    /// degrades to `.resting` — unknown capacity must not fake Zone 5.
    public static func zone(heartRate: Double, maxHeartRate: Double) -> HeartRateZone {
        guard maxHeartRate > 0 else { return .resting }
        return zone(forFraction: heartRate / maxHeartRate)
    }

    /// Integer variant of `zone(heartRate:maxHeartRate:)` — same guard, one place.
    public static func zone(bpm: Int, maxHR: Int) -> HeartRateZone {
        zone(heartRate: Double(bpm), maxHeartRate: Double(maxHR))
    }

}
