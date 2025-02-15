//
//  DefaultWeightLiftingStatsServices.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 08/02/2025.
//

import Factory
import Foundation

/// Default implementation of the `WeightLiftingStatsServices` that provides mock data for weightlifting measurements and goals.
final class DefaultWeightLiftingStatsServices: WeightLiftingStatsServices {
    
    func getLatestGoals(from history: [WeightLiftingGoalHistory]) -> [WeightLiftingGoal] {
        let allGoals = history.flatMap { $0.goals }
        let sortedGoals = allGoals.sorted { $0.createdDate > $1.createdDate }
        var newestGoals: [WeightLiftingGoal] = []
        
        for goal in sortedGoals {
            if !newestGoals.contains(where: { $0.movement == goal.movement }) {
                newestGoals.append(goal)
            }
        }
        
        return newestGoals
    }

    func mapData(
        history: [WeightLiftingGoalHistory],
        measurements: [WeightLiftingMeasurement]
    ) -> [WeightLiftingDisplayModel] {
        
        let latestGoals = getLatestGoals(from: history)
        
        return latestGoals.map { goal in
            let latestResult = measurements
                .filter { $0.name == goal.movement }
                .sorted { $0.date > $1.date }
                .first?.value ?? 0

            return WeightLiftingDisplayModel(
                id: goal.id,
                movement: goal.movement,
                goal: goal.target,
                latestResult: latestResult
            )
        }
    }
    
    // MARK: - Dummy Data Functions
    
    /// Generates dummy goal data as `WeightLiftingGoalHistory` (containing a single goal).
    ///
    /// - Parameters:
    ///   - movement: The weightlifting movement for which the goal is created.
    ///   - target: The target value for the goal.
    ///   - startDate: The date when the goal was created.
    /// - Returns: A `WeightLiftingGoalHistory` object containing a mock goal.
    func generateDummyGoalData(for movement: WeightliftingMovement, target: Double, startDate: Date) -> WeightLiftingGoalHistory {
        let goal = createMockGoal(for: movement, startDate: startDate, target: target)
        return WeightLiftingGoalHistory(
            id: UUID().uuidString,
            goals: [goal]
        )
    }
    
    /// Generates dummy measurement data for a given movement over a specified period.
    ///
    /// - Parameters:
    ///   - movement: The weightlifting movement for which measurements are generated.
    ///   - startDate: The starting date for the measurement data.
    ///   - measurementCount: The number of measurements to generate.
    ///   - goalHistories: An optional array of goal histories to associate with the measurements.
    /// - Returns: An array of `WeightLiftingMeasurement` objects.
    func generateDummyMeasurementData(for movement: WeightliftingMovement, startDate: Date, measurementCount: Int, withGoalHistory goalHistories: [WeightLiftingGoalHistory]?) -> [WeightLiftingMeasurement] {
        
        let dummyValues: [Double] = (0..<measurementCount).map { index in
            let trend = Double(index) * 0.5
            let noise = Double.random(in: -0.1...0.1)
            let rawValue = 94.0 + trend + noise
            let roundedValue = (rawValue * 2).rounded() / 2.0
            return roundedValue
        }
        
        return createMeasurements(
            for: movement,
            count: measurementCount,
            startDate: startDate,
            dummyValues: dummyValues,
            goalHistories: goalHistories
        )
    }
    
    // MARK: - Helper Functions
    
    /// Creates a mock weightlifting goal for a given movement.
    ///
    /// - Parameters:
    ///   - movement: The weightlifting movement for which the goal is created.
    ///   - startDate: The date when the goal was created.
    ///   - target: The target weight for the goal.
    /// - Returns: A `WeightLiftingGoal` object.
    private func createMockGoal(for movement: WeightliftingMovement, startDate: Date, target: Double) -> WeightLiftingGoal {
        return WeightLiftingGoal(
            id: UUID().uuidString,
            movement: movement,
            target: target,
            unit: .kg,
            createdDate: startDate
        )
    }
    
    /// Generates measurements for a given movement.
    ///
    /// Each measurement checks whether there is a goal in the provided goal history array
    /// that matches the movement and has a creation date that is earlier than or equal to the measurement date.
    ///
    /// - Parameters:
    ///   - movement: The weightlifting movement for which measurements are generated.
    ///   - count: The number of measurements to generate.
    ///   - startDate: The starting date for the measurement data.
    ///   - dummyValues: Precomputed dummy values for the measurements.
    ///   - goalHistories: An optional array of goal histories to associate with the measurements.
    /// - Returns: An array of `WeightLiftingMeasurement` objects.
    private func createMeasurements(for movement: WeightliftingMovement, count: Int, startDate: Date, dummyValues: [Double], goalHistories: [WeightLiftingGoalHistory]?) -> [WeightLiftingMeasurement] {
        let calendar = Calendar.current
        var measurements: [WeightLiftingMeasurement] = []
        
        for i in 0..<count {
            let measurementDate = calendar.date(byAdding: .weekOfYear, value: i, to: startDate)!
            
            let assignedGoalId = goalId(for: movement, measurementDate: measurementDate, in: goalHistories)
            
            let measurement = WeightLiftingMeasurement(
                id: UUID().uuidString,
                name: movement,
                date: measurementDate,
                value: dummyValues[i],
                goalId: assignedGoalId
            )
            measurements.append(measurement)
        }
        
        return measurements
    }
    
    /// Finds the appropriate goal ID based on the movement and measurement date from the goal history array.
    ///
    /// It selects a goal whose movement matches the given one and whose creation date is not later than the measurement date.
    /// If multiple such goals exist, the one with the latest creation date is chosen.
    ///
    /// - Parameters:
    ///   - movement: The weightlifting movement for which the goal is being searched.
    ///   - measurementDate: The date of the measurement.
    ///   - goalHistories: An optional array of goal histories.
    /// - Returns: The ID of the most relevant goal, or `nil` if no matching goal is found.
    private func goalId(for movement: WeightliftingMovement, measurementDate: Date, in goalHistories: [WeightLiftingGoalHistory]?) -> String? {
        guard let histories = goalHistories else { return nil }
        let matchingGoals = histories.flatMap { $0.goals }
            .filter { $0.movement == movement && $0.createdDate <= measurementDate }
        
        let selectedGoal = matchingGoals.sorted { $0.createdDate < $1.createdDate }.last
        return selectedGoal?.id
    }
    
    /// Returns a date from a specified number of weeks ago.
    ///
    /// - Parameter weeks: The number of weeks to subtract from the current date.
    /// - Returns: A `Date` object representing the date that many weeks ago.
    func dateWeeksAgo(_ weeks: Int) -> Date {
        return Calendar.current.date(byAdding: .weekOfYear, value: -weeks, to: Date()) ?? Date()
    }
    
    /// Encodes measurement data into JSON format and prints the result.
    ///
    /// - Parameter measurements: An array of `WeightLiftingMeasurement` objects to encode.
    func printDummyDataAsJSON(for measurements: [WeightLiftingMeasurement]) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        
        do {
            let jsonData = try encoder.encode(measurements)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                //print(jsonString)
            }
        } catch {
            print("JSON encoding error: \(error)")
        }
    }
}
