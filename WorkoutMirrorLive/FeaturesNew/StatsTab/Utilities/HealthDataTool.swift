//
//  HealthDataTool.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 22/11/2025.
//

import Foundation
import FoundationModels

// MARK: - Health Data Tool

struct HealthDataTool: Tool {
    var name: String = "fetchHealthMetrics"
    var description: String = "Fetch the latest health metrics (RHR, HRV, sleep, activity, readiness)."
    
    @Generable()
    struct Arguments {}
    
    func call(arguments: Arguments) async throws -> String {
        let metrics = [
            "restingHeartRate": 56,
            "hrv": 95,
            "sleepHours": 7.5,
            "activityKcal": 750,
            "trainingReadiness": 75
//            "restingHeartRate": 72,      // ⬆️ Wysoki (normalnie ~58-60)
//            "hrv": 45,                    // ⬇️ Niski (normalnie ~80-90)
//            "sleepHours": 5.2,            // ⬇️ Za mało (normalnie 7-8h)
//            "activityKcal": 1200,         // ⬆️ Ciężki trening wczoraj (normalnie ~650-750)
//            "trainingReadiness": 28       // ❌ Bardzo słaby wynik
        ] as [String : Any]
        
        return """
        Resting Heart Rate: \(metrics["restingHeartRate"]!) bpm
        HRV: \(metrics["hrv"]!) ms
        Sleep: \(metrics["sleepHours"]!) hours
        Activity: \(metrics["activityKcal"]!) kcal
        Training Readiness Score: \(metrics["trainingReadiness"]!)
        """
    }
}
