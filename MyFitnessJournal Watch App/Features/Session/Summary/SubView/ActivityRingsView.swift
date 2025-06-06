//
//  ActivityRingsView.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 31/05/2025.
//

import ComposableArchitecture
import HealthKit
import SwiftUI

struct ActivityRingsView: View {
    
    let ringData: ActivityRingData
    
    var body: some View {
        HStack {
            ActivityRingsViewTest(ringData: ringData)
                .frame(width: 50, height: 50)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(String(format: "%.0f/%.0f", ringData.moveValue, ringData.moveGoal))
                    .foregroundColor(.pink)
                Text(String(format: "%.0f/%.0fM", ringData.exerciseValue, ringData.exerciseGoal))
                    .foregroundColor(.green)
                Text(String(format: "%.0f/%.0fH", ringData.standValue, ringData.standGoal))
                    .foregroundColor(.cyan)
            }
            .font(.system(size: 14, weight: .medium, design: .rounded))
            Spacer()
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

struct ActivityRingData: Equatable {
    var moveValue: Double
    var moveGoal: Double
    var exerciseValue: Double
    var exerciseGoal: Double
    var standValue: Double
    var standGoal: Double
}

struct ActivityRingsViewTest: WKInterfaceObjectRepresentable {
    
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


struct ActivityRingsView2: WKInterfaceObjectRepresentable {
    
    let healthStore: HKHealthStore
    
    // MARK: - API
    
    func makeWKInterfaceObject(context: Context) -> some WKInterfaceObject {
        let activityRingsObject = WKInterfaceActivityRing()

        let calendar = Calendar.current
        var components = calendar.dateComponents([.era, .year, .month, .day], from: Date())
        components.calendar = calendar

        let predicate = HKQuery.predicateForActivitySummary(with: components)
        let query = HKActivitySummaryQuery(predicate: predicate) { query, summaries, error in
            DispatchQueue.main.async {
                activityRingsObject.setActivitySummary(summaries?.first, animated: true)
            }
        }

        healthStore.execute(query)

        return activityRingsObject
    }

    func updateWKInterfaceObject(_ wkInterfaceObject: WKInterfaceObjectType, context: Context) {

    }
    
    
}
