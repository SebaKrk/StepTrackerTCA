//
//  TrainingReadinessMetricsTool.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 22/11/2025.
//

import Foundation
import FoundationModels
import SharedModels

@available(iOS 26, *)
struct TrainingReadinessMetricsTool: Tool {
    
    private let result: TrainingReadinessResult
    
    var name: String = "trainingReadinessMetricsTool"
    var description: String = "Fetch the latest health metrics (RHR, HRV, sleep, activity, readiness)."
    
    @Generable()
    struct Arguments: Codable {}
    
    init(result: TrainingReadinessResult) {
        self.result = result
    }
    
    func call(arguments: Arguments) async throws -> String {
        let rhr = result.components.restingHeartRate
        let hrv = result.components.heartRateVariability
        let sleep = result.components.sleepQuality
        let activity = result.components.previousDayLoad
        
        var output: [String] = []
        
        if let rhr = rhr {
            let baseline = rhr.baselineValue.map { String(format: "%.1f", $0) } ?? "N/A"
            output.append("Resting Heart Rate: \(String(format: "%.1f", rhr.currentValue)) bpm (baseline: \(baseline) bpm)")
        }
        
        if let hrv = hrv {
            let baseline = hrv.baselineValue.map { String(format: "%.1f", $0) } ?? "N/A"
            output.append("HRV: \(String(format: "%.1f", hrv.currentValue)) ms (baseline: \(baseline) ms)")
        }
        
        if let sleep = sleep {
            let baseline = sleep.baselineValue.map { String(format: "%.1f", $0) } ?? "N/A"
            output.append("Sleep: \(String(format: "%.1f", sleep.currentValue)) hours (baseline: \(baseline) hours)")
        }
        
        if let activity = activity {
            let baseline = activity.baselineValue.map { String(format: "%.0f", $0) } ?? "N/A"
            output.append("Activity: \(String(format: "%.0f", activity.currentValue)) kcal (baseline: \(baseline) kcal)")
        }
        
        output.append("Training Readiness Score: \(result.overallScore)")
        
        return output.joined(separator: "\n")
    }
    
}
//
//// MARK: - Health Data Tool
//
//struct HealthDataTool: Tool {
//    var name: String = "fetchHealthMetrics"
//    var description: String = "Fetch the latest health metrics (RHR, HRV, sleep, activity, readiness)."
//    
//    @Generable()
//    struct Arguments {}
//    
//    func call(arguments: Arguments) async throws -> String {
//        let metrics = [
//            "restingHeartRate": 56,
//            "hrv": 95,
//            "sleepHours": 7.5,
//            "activityKcal": 750,
//            "trainingReadiness": 75
////            "restingHeartRate": 72,      // ⬆️ Wysoki (normalnie ~58-60)
////            "hrv": 45,                    // ⬇️ Niski (normalnie ~80-90)
////            "sleepHours": 5.2,            // ⬇️ Za mało (normalnie 7-8h)
////            "activityKcal": 1200,         // ⬆️ Ciężki trening wczoraj (normalnie ~650-750)
////            "trainingReadiness": 28       // ❌ Bardzo słaby wynik
//        ] as [String : Any]
//        
//        return """
//        Resting Heart Rate: \(metrics["restingHeartRate"]!) bpm
//        HRV: \(metrics["hrv"]!) ms
//        Sleep: \(metrics["sleepHours"]!) hours
//        Activity: \(metrics["activityKcal"]!) kcal
//        Training Readiness Score: \(metrics["trainingReadiness"]!)
//        """
//    }
//}
