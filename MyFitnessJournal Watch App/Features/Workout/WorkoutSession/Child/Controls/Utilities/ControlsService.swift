//
//  ControlsService.swift
//  MyFitnessJournal Watch App
//
//  Created by Sebastian Sciuba on 23/05/2025.
//

import Factory
import Foundation

protocol ControlsService {
    
    ///
    var workoutSessionIsRunning: Bool { get }
    
    ///
    func togglePause()
    
    ///
    func endWorkout()
    
}

final class DefaultControlsService: ControlsService {

    // MARK: - Dependency
    
    @Injected(\.workoutManager) private var workoutManager
    
    // MARK: - API
    
    var workoutSessionIsRunning: Bool {
        workoutManager.workoutSessionIsRunning
    }
    
    func togglePause() {
        workoutManager.togglePause()
    }
    
    func endWorkout() {
        workoutManager.endWorkout()
    }
    
}
