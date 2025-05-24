//
//  HKLiveWorkoutBuilderDelegate.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 23/05/2025.
//

import Foundation
import HealthKit

extension DefaultWorkoutManager: HKLiveWorkoutBuilderDelegate {
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState,
                        from fromState: HKWorkoutSessionState, date: Date) {
        DispatchQueue.main.async {
            self.workoutSessionIsRunning = toState == .running
        }

        if toState == .ended {
            builder?.endCollection(withEnd: date) { (success, error) in
                self.builder?.finishWorkout { (workout, error) in
                    DispatchQueue.main.async {
                        self.workout = workout
                    }
                }
            }
        }
    }

    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) { }
    
}
