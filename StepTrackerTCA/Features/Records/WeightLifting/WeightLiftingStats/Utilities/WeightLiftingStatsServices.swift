//
//  WeightLiftingStatsServices.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 08/02/2025.
//

import Foundation

/// A protocol defining a service responsible for managing weightlifting statistics.
protocol WeightLiftingStatsServices {
    
    /// Generates a goal history containing a single weightlifting goal.
    ///
    /// - Parameters:
    ///   - movement: The weightlifting movement for which the goal is created.
    ///   - target: The target weight for the goal.
    ///   - startDate: The date when the goal was created.
    /// - Returns: A `WeightLiftingGoalHistory` object containing the generated goal.
    func generateDummyGoalData(for movement: WeightliftingMovement, target: Double, startDate: Date) -> WeightLiftingGoalHistory

    /// Generates a set of dummy weightlifting measurements.
    ///
    /// - Parameters:
    ///   - movement: The weightlifting movement for which measurements are generated.
    ///   - startDate: The starting date for measurement generation (e.g., the date of the first recorded measurement).
    ///   - measurementCount: The number of measurements to generate (e.g., the number of weeks for which data is generated).
    ///   - goalHistories: An optional array of goal history objects used to match measurements with relevant goals.
    /// - Returns: An array of generated `WeightLiftingMeasurement` objects.
    func generateDummyMeasurementData(for movement: WeightliftingMovement, startDate: Date, measurementCount: Int, withGoalHistory goalHistories: [WeightLiftingGoalHistory]?) -> [WeightLiftingMeasurement]

    /// Returns a date corresponding to a given number of weeks in the past.
    ///
    /// - Parameter weeks: The number of weeks to go back in time.
    /// - Returns: A `Date` object representing the past date.
    func dateWeeksAgo(_ weeks: Int) -> Date

    /// Encodes an array of `WeightLiftingMeasurement` objects into JSON format and prints the result to the console.
    ///
    /// - Parameter measurements: The array of weightlifting measurement data to be encoded.
    func printDummyDataAsJSON(for measurements: [WeightLiftingMeasurement])
}
