//
//  ExerciseWorkoutType.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 10/07/2025.
//


import Foundation

// MARK: - Exercise Workout Type
public enum ExerciseWorkoutType: String, CaseIterable, Sendable {
    case amrap
    case forTime
    case emom
    case tabata

    public var displayName: String {
        switch self {
        case .amrap: return "AMRAP"
        case .forTime: return "For Time"
        case .emom: return "EMOM"
        case .tabata: return "Tabata"
        }
    }
    
    public var fullDescription: String {
        switch self {
        case .amrap: return "As Many Rounds As Possible"
        case .forTime: return "Complete as fast as possible"
        case .emom: return "Every Minute On the Minute"
        case .tabata: return "20 seconds work / 10 seconds rest"
        }
    }
    
    public var aliases: [String] {
        switch self {
        case .amrap:
            return ["AMRAP", "as many rounds as possible", "amrap"]
        case .forTime:
            return ["For Time", "for time", "FT", "as fast as possible"]
        case .emom:
            return ["EMOM", "every minute on the minute", "emom"]
        case .tabata:
            return ["Tabata", "tabata", "20/10", "20 on 10 off"]
        }
    }
    
    public var defaultTimeCapMinutes: Int? {
        switch self {
        case .amrap: return 15
        case .forTime: return 20
        case .emom: return 12
        case .tabata: return 4
        }
    }
    
    public var isTimerRequired: Bool {
        switch self {
        case .amrap: return true
        case .forTime: return false // może mieć time cap, ale nie jest wymagany
        case .emom: return true
        case .tabata: return true
        }
    }
    
}

