//
//  DataAnalyzer.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 10/11/2025.

import Foundation
import FoundationModels
//import Playgrounds

@available(iOS 26, *)
@Observable
final class DataAnalyzer {
    
    static let shared = DataAnalyzer()
    
    let model: SystemLanguageModel = .default
    
    var available: Bool {
        switch model.availability {
            
        case .available:
            print("DataAnalyzer - available")
            return true
        case let .unavailable(info):
            print("DataAnalyzer - unavailable \(info)")
            return false
        }
    }
    
    func analyzeHealthData() async {
        let instructions = """
    You are a fitness data interpreter. Analyze ONLY the values provided in each request. 
    Do not guess, do not assume trends, and do not reference past data unless explicitly provided.
    Your job is to interpret the current metrics exactly as given and explain what they mean for today.
    At the end of each response, provide a clear summary indicating whether I should train today and what training intensity is appropriate.
    Base all insights strictly on the provided inputs and nothing else.
    """
        let session = LanguageModelSession(model: .default, tools: [HealthDataTool()], instructions: instructions)
        let prompt = """
     Use the `fetchHealthMetrics` tool to obtain today's health metrics.
     Analyze the returned values and provide a clear interpretation of what they mean for my current condition and daily readiness.
     """
        do {
            let response = try await session.respond(to: prompt, options: .init(sampling: .greedy,
                                                                                temperature: 0.1,
                                                                                       maximumResponseTokens: 200))
            print(response.content)
        } catch {
            print(error.localizedDescription)
        }
    }
    
    private init() {}
    
}

import Foundation
import HealthKit

struct HealthDataTool: Tool {
    var name: String = "fetchHealthMetrics"
    var description: String = "Fetch the latest health metrics (RHR, HRV, sleep, activity, readiness)."
    
    @Generable()
    struct Arguments {
        // Nie potrzebujesz argumentów → ale struktura musi istnieć
    }
    
    func call(arguments: Arguments) async throws -> String {
        // Tutaj pobierasz realne dane z HealthKit lub z własnego storage
        // To są przykładowe wartości — zamienisz na swoje:
        
        let metrics = [
            "restingHeartRate": 56,
            "hrv": 95,
            "sleepHours": 7.5,
            "activityKcal": 750,
            "trainingReadiness": 75
        ] as [String : Any]
        
        // Zwracasz czysty tekst → model to przeczyta
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
