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
        print("toggle pause - current state: \(workoutSessionIsRunning)")
        
        guard let session = session else {
            print("❌ No session to pause/resume")
            return
        }
        
        if workoutSessionIsRunning {
            pause()
        } else {
            resume()
        }
    }
    
    func endWorkout() {
        print("🛑 endWorkout() called")
        
        guard let session = session else {
            print("❌ No session to end")
            return
        }
        
        session.end()
        print("📤 session.end() called")
    }
    
    // MARK: - Private Helpers
    
    private func pause() {
        session?.pause()
        print("⏸️ Pausing workout session")
#if DEBUG
        print("⏸️ Pausing workout session")
#endif
    }
    
    private func resume() {
        session?.resume()
        print("▶️ Resuming workout session")
    }
}
