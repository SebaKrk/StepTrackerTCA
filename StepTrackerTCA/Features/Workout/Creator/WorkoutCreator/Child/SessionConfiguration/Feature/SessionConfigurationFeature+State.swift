//
//  SessionConfigurationFeature+State.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 18/07/2025.
//

import ComposableArchitecture
import SharedModels

/// Implementation of `SessionConfigurationFeature` state
extension SessionConfigurationFeature {
    
    @ObservableState
    struct State {
        
        // MARK: - Properties
        
        /// Type of phase being configured (warmUp or coolDown)
        let phaseType: PhaseType
        
        /// Current goal setting for the session
        var goal: SimpleWorkoutGoal = .open
        
        /// Time in minutes (only used when goal is timeLimit)
        var time: Int? = nil
        
        /// Additional notes or description for the session
        var note: String = ""
        
        /// Controls presentation of the note editing sheet
        var isNoteSheetPresented: Bool = false
        
        /// Available time options for the picker (5-60 minutes in 5-minute increments)
        var availableTime: [Int] = Array(stride(from: 5, through: 60, by: 5))
        
        // MARK: - Computed Properties
        
        /// Display title based on phase type
        var title: String {
            phaseType.title
        }
        
        /// Placeholder text for note input field
        var notePlaceholder: String {
            phaseType.infoPlaceholder
        }
        
        /// Display text showing current configuration (goal or time)
        var displayText: String {
            if goal == .open {
                return goal.title
            } else {
                return "\(time ?? 0) minutes"
            }
        }
        
        /// Text for the info/note button
        var infoButtonText: String {
            note.isEmpty ? "add info" : note
        }
        
        /// Converts current state to WarmUpSession model
        var toWarmUpSession: WarmUpSession {
            WarmUpSession(
                goal: goal,
                time: goal == .open ? nil : time,
                description: note.isEmpty ? nil : note
            )
        }
        
        /// Converts current state to CoolDownSession model
        var toCoolDownSession: CoolDownSession {
            CoolDownSession(
                goal: goal,
                time: goal == .open ? nil : time,
                description: note.isEmpty ? nil : note
            )
        }
        
        // MARK: - Initializers
        
        /// Creates a new state with the specified phase type
        /// - Parameter phaseType: The type of phase to configure
        init(phaseType: PhaseType) {
            self.phaseType = phaseType
        }
        
        /// Creates a new state initialized with existing WarmUpSession data
        /// - Parameters:
        ///   - phaseType: The type of phase (should be .warmUp)
        ///   - warmUpSession: Existing warm up session to load data from
        init(phaseType: PhaseType, warmUpSession: WarmUpSession) {
            self.phaseType = phaseType
            self.goal = warmUpSession.goal
            self.time = warmUpSession.time
            self.note = warmUpSession.description ?? ""
        }
        
        /// Creates a new state initialized with existing CoolDownSession data
        /// - Parameters:
        ///   - phaseType: The type of phase (should be .coolDown)
        ///   - coolDownSession: Existing cool down session to load data from
        init(phaseType: PhaseType, coolDownSession: CoolDownSession) {
            self.phaseType = phaseType
            self.goal = coolDownSession.goal
            self.time = coolDownSession.time
            self.note = coolDownSession.description ?? ""
        }
    }
    
}
