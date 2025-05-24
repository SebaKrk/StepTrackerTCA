//
//  WorkoutSessionStateControl.swift
//  MyFitnessJournal Watch App
//
//  Created by Sebastian Sciuba on 23/05/2025.
//

import Foundation

extension DefaultWorkoutManager {
    
    // MARK: - Session State Control

    func togglePause() {
        if workoutSessionIsRunning == true {
            self.pause()
        } else {
            resume()
        }
    }

    func pause() {
        session?.pause()
    }

    func resume() {
        session?.resume()
    }

    func endWorkout() {
        session?.end()
        //showingSummaryView = true
    }
    
}
