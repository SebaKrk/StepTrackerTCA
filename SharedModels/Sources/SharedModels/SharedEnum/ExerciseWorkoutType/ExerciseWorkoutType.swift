//
//  ExerciseWorkoutType.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 10/07/2025.
//


import Foundation
import SwiftUI

// MARK: - Exercise Workout Type
public enum ExerciseWorkoutType: String, CaseIterable, Sendable {
    case amrap
    case forTime
    case emom
    case tabata
    case strength
    case olympicWeightlifting

    public var displayName: String {
        switch self {
        case .amrap:                return "AMRAP"
        case .forTime:              return "For Time"
        case .emom:                 return "EMOM"
        case .tabata:               return "Tabata"
        case .strength:             return "Strength"
        case .olympicWeightlifting: return "Olympic WL"
        }
    }

    public var fullDescription: String {
        switch self {
        case .amrap:                return "As Many Rounds As Possible"
        case .forTime:              return "Complete as fast as possible"
        case .emom:                 return "Every Minute On the Minute"
        case .tabata:               return "20 seconds work / 10 seconds rest"
        case .strength:             return "Weight training with sets and reps"
        case .olympicWeightlifting: return "Olympic weightlifting — snatch, clean & jerk"
        }
    }

    public var aliases: [String] {
        switch self {
        case .amrap:                return ["AMRAP", "as many rounds as possible", "amrap"]
        case .forTime:              return ["For Time", "for time", "FT", "as fast as possible"]
        case .emom:                 return ["EMOM", "every minute on the minute", "emom"]
        case .tabata:               return ["Tabata", "tabata", "20/10", "20 on 10 off"]
        case .strength:             return ["Strength", "strength", "S&C"]
        case .olympicWeightlifting: return ["Weightlifting", "weightlifting", "Olympic", "OLY"]
        }
    }

    public var defaultTimeCapMinutes: Int? {
        switch self {
        case .amrap:                return 15
        case .forTime:              return 20
        case .emom:                 return 12
        case .tabata:               return 4
        case .strength:             return nil
        case .olympicWeightlifting: return nil
        }
    }

    public var isTimerRequired: Bool {
        switch self {
        case .amrap:                return true
        case .forTime:              return false
        case .emom:                 return true
        case .tabata:               return true
        case .strength:             return false
        case .olympicWeightlifting: return false
        }
    }

    public var color: Color {
        switch self {
        case .amrap:                return .red
        case .forTime:              return .blue
        case .emom:                 return .green
        case .tabata:               return .yellow
        case .strength:             return .orange
        case .olympicWeightlifting: return .purple
        }
    }
}

