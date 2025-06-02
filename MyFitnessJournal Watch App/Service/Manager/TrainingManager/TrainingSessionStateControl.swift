//
//  TrainingSessionStateControl.swift
//  MyFitnessJournal Watch App
//
//  Created by Sebastian Sciuba on 31/05/2025.
//

import Foundation

extension DefaultTrainingManager {
    
    // MARK: - Session State Control (Protocol)
    
    func togglePause() {
        guard let session = session else {
            return
        }
        
        if workoutSessionIsRunning {
            pause()
        } else {
            resume()
        }
    }
    
    func endWorkout() {
        guard let session = session else {
            return
        }
        
        session.end()
    }
    
    // MARK: - Private Helpers
    
    private func pause() {
        session?.pause()
    }
    
    private func resume() {
        session?.resume()
    }
}
