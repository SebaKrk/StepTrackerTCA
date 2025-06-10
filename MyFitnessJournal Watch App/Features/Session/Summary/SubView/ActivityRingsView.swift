//
//  ActivityRingsView.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 31/05/2025.
//

import ComposableArchitecture
import HealthKit
import SwiftUI
import SharedModels

struct ActivityRingsView: WKInterfaceObjectRepresentable {
    
    let ringData: ActivityRingData
    
    func makeWKInterfaceObject(context: Context) -> WKInterfaceActivityRing {
        WKInterfaceActivityRing()
    }
    
    func updateWKInterfaceObject(_ object: WKInterfaceActivityRing, context: Context) {
        let summary = HKActivitySummary()
        
        summary.activeEnergyBurned = HKQuantity(unit: .kilocalorie(), doubleValue: ringData.moveValue)
        summary.activeEnergyBurnedGoal = HKQuantity(unit: .kilocalorie(), doubleValue: ringData.moveGoal)
        
        summary.appleExerciseTime = HKQuantity(unit: .minute(), doubleValue: ringData.exerciseValue)
        summary.appleExerciseTimeGoal = HKQuantity(unit: .minute(), doubleValue: ringData.exerciseGoal)
        
        summary.appleStandHours = HKQuantity(unit: .count(), doubleValue: ringData.standValue)
        summary.appleStandHoursGoal = HKQuantity(unit: .count(), doubleValue: ringData.standGoal)
        
        object.setActivitySummary(summary, animated: true)
    }
    
}
