//
//  CountDownFeature+State.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 20/06/2025.
//

import ComposableArchitecture
import Foundation
import HealthKit

extension CountDownFeature {
    
    @ObservableState
    struct State: Equatable {
        
        /// The currently selected workout activity type, e.g., running, cycling.
        var selectedWorkout: HKWorkoutActivityType?
        
        var timeRemaining: TimeInterval = 3
        
        var duration: TimeInterval = 3
        
        var isActive: Bool = false
        
        var endDate: Date?
        
        var timerFinished: Bool = false
        
        var trimValue: Double {
            timeRemaining > 0 ? timeRemaining / duration : 0
        }
        
        var isSettingTrim: Bool {
            timeRemaining == duration
        }
    }
    
}
