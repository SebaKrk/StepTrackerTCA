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
    
    private init() {}
    
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
