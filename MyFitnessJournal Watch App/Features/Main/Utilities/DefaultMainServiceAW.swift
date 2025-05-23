//
//  DefaultMainServiceAW.swift
//  MyFitnessJournal Watch App
//
//  Created by Sebastian Sciuba on 23/05/2025.
//

import Factory
import Foundation

final class DefaultMainServiceAW: MainServiceAW {
    
    // MARK: - Dependency
    
    @Injected(\.workoutManager) private var workoutManager
    
    // MARK: - API
    
    func requestAuthorization() {
        workoutManager.requestAuthorization()
    }
    
}
