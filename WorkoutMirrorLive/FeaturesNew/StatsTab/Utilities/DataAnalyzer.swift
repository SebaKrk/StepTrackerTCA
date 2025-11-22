//
//  DataAnalyzer.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 10/11/2025.

import Foundation
import FoundationModels
import Observation

@available(iOS 26, *)
@Observable
final class DataAnalyzer {
    
    static let shared = DataAnalyzer()
    
    let model: SystemLanguageModel = .default
    
    var isThinking = false
    
    var coachMessage: String.PartiallyGenerated?
    
    var available: Bool {
        get async {
            switch model.availability {
            case .available:
                return true
            case .unavailable:
                return false
            }
        }
    }
    
    private init() {}
    
    func analyzeHealthData() async {
        isThinking = true
        coachMessage = nil
        
        let instructions = """
        You are a fitness data interpreter. Analyze ONLY the values provided in each request.
        Do not guess, do not assume trends, and do not reference past data unless explicitly provided.

        **CRITICAL: Training Readiness Score Scale (0-100):**
        The Training Readiness Score is calculated from 4 components with a baseline of 50 points.
        DO NOT mention point values in your response - only interpret the overall score and components.

        **Overall Score Interpretation:**
        - 0-30: Critical Recovery Needed
          → Complete rest required. Body is severely fatigued or stressed.
          → No training recommended. Focus on sleep, nutrition, and stress management.

        - 31-50: Low Readiness
          → Active recovery only (walking, stretching, light mobility).
          → Avoid any moderate or high-intensity training.

        - 51-70: Moderate Readiness
          → Light to moderate training intensity acceptable.
          → Monitor how you feel during warm-up and adjust accordingly.
          → Avoid high-intensity or heavy volume sessions.

        - 71-85: Good Readiness
          → Normal training intensity and volume appropriate.
          → Body is well-recovered and ready for standard workouts.

        - 86-100: Excellent Readiness
          → Optimal condition for high-intensity training.
          → Body is fully recovered. Great day for PRs or challenging sessions.

        **Component Scoring System (for your understanding - DO NOT mention points in response):**

        1. **Resting Heart Rate (RHR):**
           - Measured: This morning
           - Baseline: 7-day morning average
           - Point range: -15 to +15
           
           Interpretation:
           • 3+ bpm below baseline: Excellent recovery
           • 1-3 bpm below baseline: Good recovery
           • Within ±1 bpm: Normal state
           • 2-5 bpm above baseline: Suboptimal recovery
           • 5+ bpm above baseline: Poor recovery, possible stress or illness

        2. **Heart Rate Variability (HRV) - HIGHER IS BETTER:**
           - Measured: Last night during sleep
           - Baseline: 7-day average
           - Point range: -15 to +15
           
           Interpretation:
           • 10+ ms above baseline: Excellent autonomic balance
           • 5-10 ms above baseline: Good recovery
           • Within ±5 ms: Normal state
           • 5-10 ms below baseline: Suboptimal recovery, possible fatigue
           • 10+ ms below baseline: High stress or significant fatigue

        3. **Sleep Quality:**
           - Measured: Last night's duration
           - Baseline: 7-night average
           - Point range: -10 to +15
           
           Interpretation:
           • 7-9 hours: Optimal recovery
           • 6-7 or 9-10 hours: Acceptable
           • <6 or >10 hours: Suboptimal
           • Significantly more than baseline: Extra recovery benefit
           • Significantly less than baseline: Sleep debt concern

        4. **Previous Day Activity Load:**
           - Measured: Yesterday's total active energy
           - Baseline: 7-day average
           - Point range: -10 to +5
           
           Interpretation (as % of baseline):
           • 0-15%: Complete rest day - fully recovered
           • 15-45%: Active recovery day - optimal freshness
           • 45-80%: Light training - well recovered
           • 80-130%: Normal training load - neutral
           • 130-180%: Heavy training - moderate residual fatigue
           • 180%+: Very heavy training - significant fatigue present

        **Response Format Requirements:**

        Your response must include:

        1. **Component Analysis** (describe in plain language, NO points):
           - Resting Heart Rate: [value] bpm vs baseline [value] bpm → [interpretation in words]
           - HRV: [value] ms vs baseline [value] ms → [interpretation in words]
           - Sleep: [value] hours vs baseline [value] hours → [interpretation in words]
           - Yesterday's Activity: [value] kcal vs baseline [value] kcal → [interpretation in words]

        2. **Overall Assessment:**
           - Training Readiness Score: [0-100]
           - Readiness Level: [Critical/Low/Moderate/Good/Excellent]

        3. **Clear Recommendation:**
           ✅ or ❌ Should you train today? [YES/NO]
           - Recommended activity level: [Complete rest/Active recovery/Light-moderate/Normal/High intensity]
           - Brief guidance tailored to the readiness level

        **Important:**
        - DO NOT mention point values, scores, or "+/-" in your response
        - Use descriptive language: "excellent", "good", "within normal range", "elevated", "below baseline"
        - If any metric shows 0 or clearly invalid values, mention "Invalid sensor data"
        - Base recommendations strictly on the overall readiness score interpretation
        - Keep response concise (2-3 short paragraphs maximum)
        """
        
        let session = LanguageModelSession(
            model: .default,
            tools: [HealthDataTool()],
            instructions: instructions
        )
        
        let prompt = """
        Use the `fetchHealthMetrics` tool to obtain today's health metrics.
        Analyze the returned values and provide a clear interpretation of what they mean for my current condition and daily readiness.
        """
        
        do {
            let stream = session.streamResponse(
                to: prompt,
                options: .init(
                    sampling: .greedy,
                    temperature: 0.1,
                    maximumResponseTokens: 200
                )
            )
            
            for try await partial in stream {
                isThinking = false
                if partial.content != "null" {
                    coachMessage = partial.content
                    print(coachMessage!)
                }
            }
        } catch {
            isThinking = false
            print("Error: \(error.localizedDescription)")
        }
    }
}

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
//@available(iOS 26, *)
//#Playground {
//    let session = LanguageModelSession()
//    let promot =
//    //"My heart rate during the night was 56 bpm — what does that mean?"
//    //"What are the number of remodeled steps per day for a 40 year old man"
//    """
//    Analyze my daily recovery based on today's biometrics:
//
//    - Resting heart rate (RHR): 52 bpm
//    - Heart rate variability (HRV): 83.6 ms
//    - Sleep duration: 8.6 hours
//    - Yesterday's activity: 575 kcal
//
//    Please explain:
//    1. What is my recovery status today?
//    2. Is it recommended for me to train today?
//    3. How intense should the training be?
//
//    Answer in clear and simple language.
//    """
//
//    do {
//        let response = try await session.respond(to: promot)
//        print(response.content)
//    } catch {
//        print(error)
//    }
//}
