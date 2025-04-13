//
//  SubmissionType.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 13/04/2025.
//

import Foundation

/// Represents different submission operations that determine which strategy to use.
enum SubmissionType {
    case submit
    case setGoal
    
    /// A human-readable title for the submission type, used for UI display.
    var title: String {
         switch self {
         case .submit:
             return "Submit new Workout"
         case .setGoal:
             return "Set new Goal"
         }
     }
}
