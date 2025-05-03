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
        
        /// The workout for which heart rate details are being displayed.
        var workout: HKWorkout
        
        /// The list of heart rate quantity samples fetched from HealthKit.
        var sample: [HKQuantitySample] = []
        
        /// The processed per-minute heart rate metrics derived from the samples.
        var hrData: [HeartRateMetricsMinute] = []
        
        /// The type of workout (e.g., running, cycling) as a human-readable string.
        var workoutType: String { workout.workoutActivityType.name }
        
        /// The start time of the workout.
        var startWorkout: Date { workout.startDate }
        
        /// The end time of the workout.
        var endWorkout: Date { workout.endDate }
        
        ///
        var workoutDurationInMinutes: Double {
            workout.endDate.timeIntervalSince(workout.startDate) / 60
        }
        
        /// A Boolean flag indicating whether the workout details view is expanded.
        var isExpandDetails: Bool = false
        
        ///
        var isExpandDetailsByMinute: Bool = false
        
        /// The lowest recorded heart rate during the workout.
        var lowestMinHR: Double = 0
        
        /// The highest recorded heart rate during the workout.
        var highestMaxHR: Double = 0
        
        /// The amount of active energy burned during the workout, in kilocalories.
        var activeEnergyBurned: Double = 0
        
        /// The starting position of the scroll view, set to one minute into the workout.
        //var scrollPositionStart: Date = .now
        
        var rawSelectedDate: Date?
        
        var selectedHeartRateMetric: HeartRateMetricsMinute?
        
    }
    
}
