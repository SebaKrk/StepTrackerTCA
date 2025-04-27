//
//  HeartRateDetailsFeature+State.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 27/04/2025.
//

import ComposableArchitecture
import Foundation
import HealthKit

extension HeartRateDetailsFeature {
    
    // MARK: - State
    @ObservableState
    struct State {
        
        ///
        var workout: HKWorkout
        
        ///
        var sample: [HKQuantitySample] = []
        
        ///
        var hrData: [HeartRateMetricsMinute] = []
        
        ///
        var workoutType: String { workout.workoutActivityType.name }
        
        ///
        var startWorkout: Date { workout.startDate }
        
        ///
        var endWorkout: Date { workout.endDate }
        
        ///
        var isExpandDetails: Bool = false
        
        ///
        var lowestMinHR: Double = 0
        
        ///
        var highestMaxHR: Double = 0
        
        var activeEnergyBurned: Double = 0
        
        /// Scroll start set to one minute into the workout
        var scrollPositionStart: Date = .now
        
        /// All minute-level HR metrics for the hour of scrollPositionStart
        var hrMetricsForCurrentHour: [HeartRateMetricsMinute] {
            let calendar = Calendar.current
            guard let hourStart = calendar.dateInterval(of: .hour, for: scrollPositionStart)?.start else { return [] }
            return hrData.filter { calendar.isDate($0.minute, equalTo: hourStart, toGranularity: .hour) }
        }

        /// Average HR (mean of min and max) for the exact minute at scrollPositionStart
        var averageHRAtScrollPosition: Int? {
            let calendar = Calendar.current
            guard let minuteStart = calendar.dateInterval(of: .minute, for: scrollPositionStart)?.start,
                  let metrics = hrData.first(where: { $0.minute == minuteStart }) else {
                return nil
            }
            return Int((metrics.minHR + metrics.maxHR) / 2)
        }
    }
    
}
