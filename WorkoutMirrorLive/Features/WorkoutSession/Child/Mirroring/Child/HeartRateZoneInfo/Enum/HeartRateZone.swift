//
//  HeartRateZone.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 07/08/2025.
//

import SwiftUI

public enum HeartRateZone: String, CaseIterable, Identifiable {
    
    case resting = "Resting"             // 0-50% HR max
    case recovery = "Recovery"           // 50-60% HR max
    case fatBurning = "Fat Burning"      // 60-70% HR max
    case aerobic = "Aerobic"             // 70-80% HR max
    case threshold = "Threshold"         // 80-90% HR max
    case anaerobic = "Anaerobic"         // 90-100% HR max
    
    public var id: String { rawValue }
    
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
        case .resting: return "Complete rest, minimal activity"
        case .recovery: return "Light activity, active recovery"
        case .fatBurning: return "Comfortable pace, fat burning"
        case .aerobic: return "Moderate effort, aerobic base"
        case .threshold: return "Hard effort, lactate threshold"
        case .anaerobic: return "Very hard, anaerobic power"
        }
    }
    
    public var detailedDescription: String {
        switch self {
        case .resting:
            return """
            The resting zone represents your baseline heart rate during complete rest, sleep, or minimal daily activities. This is your body's natural recovery state where cellular repair, hormone regulation, and nervous system restoration occur. Maintaining a healthy resting heart rate indicates good cardiovascular fitness and overall health. This zone is essential for stress recovery, sleep quality, and preparing your body for active periods.
            """
            
        case .recovery:
            return """
            The recovery zone is the lightest level of physical activity, perfect for rest days or active recovery after intense training sessions. In this zone, your body effectively removes metabolic waste products, improves blood circulation, and supports muscle repair processes. By staying in this zone, you enhance flexibility, accelerate recovery, and prepare your body for future training challenges without additional physiological stress.
            """
            
        case .fatBurning:
            return """
            The fat burning zone is the optimal range for those wanting to lose weight and improve metabolic efficiency. At this pace, your body primarily uses fatty acids as an energy source, leading to effective fat tissue burning. Long-duration training in this zone improves your body's ability to oxidize fats, increases insulin sensitivity, and builds a solid aerobic base without excessive fatigue.
            """
            
        case .aerobic:
            return """
            The aerobic zone forms the foundation of endurance and is crucial for developing the cardiorespiratory system. Training in this range maximizes oxygen uptake, increases the number and size of mitochondria in muscles, and improves heart efficiency. By staying in this zone, you develop base endurance, increase stroke volume, and improve overall physical capacity, which forms the basis for all other forms of activity.
            """
            
        case .threshold:
            return """
            The threshold zone is the intensity at which your body balances between aerobic and anaerobic metabolism. In this range, there's an equilibrium between lactate production and removal. Threshold training significantly improves your lactate threshold, increases critical power, and develops the ability to maintain high intensity for extended periods. This is a key zone for improving athletic performance and capacity in submaximal efforts.
            """
            
        case .anaerobic:
            return """
            The anaerobic zone is the highest training intensity where your body works primarily in the anaerobic system. Significant lactate accumulation and rapid depletion of muscle glycogen occur here. Training in this zone develops anaerobic power, increases lactate buffering capacity, and improves the ability to perform very intense, short-duration efforts. This zone should be used sparingly due to high metabolic stress and long recovery times.
            """
        }
    }
    
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
    
}
