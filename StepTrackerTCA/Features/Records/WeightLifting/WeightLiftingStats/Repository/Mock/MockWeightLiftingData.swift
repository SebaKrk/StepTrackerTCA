//
//  MockWeightLiftingData.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 15/02/2025.
//

import Foundation

struct MockWeightLiftingData {
    
    // MARK: - API
    
    static func getDummyData() async -> (dummyData: [WeightLiftingMeasurement], goalHistory: [WeightLiftingGoalHistory]) {
        let overheadSquatOldGoalDate = dateWeeksAgo(10)
        let overheadSquatNewGoalDate = dateWeeksAgo(2)
        
        let oldGoal = generateDummyGoalData(
            for: .overheadSquat,
            target: 80.0,
            startDate: overheadSquatOldGoalDate
        )
        let newGoal = generateDummyGoalData(
            for: .overheadSquat,
            target: 90.0,
            startDate: overheadSquatNewGoalDate
        )
        let cleanAndJerkGoalStart = dateWeeksAgo(5)
        let cleanAndJerkGoal = generateDummyGoalData(
            for: .cleanAndJerk,
            target: 110.0,
            startDate: cleanAndJerkGoalStart
        )
        
        let goalHistory: [WeightLiftingGoalHistory] = [oldGoal, newGoal, cleanAndJerkGoal]
        
        let startDateForMeasurements = dateWeeksAgo(12)
        let overheadSquatMeasurements = generateDummyMeasurementData(
            for: .overheadSquat,
            startDate: startDateForMeasurements,
            measurementCount: 2,
            withGoalHistory: goalHistory
        )
        let cleanAndJerkMeasurements = generateDummyMeasurementData(
            for: .cleanAndJerk,
            startDate: startDateForMeasurements,
            measurementCount: 12,
            withGoalHistory: goalHistory
        )
        
        let dummyData = overheadSquatMeasurements + cleanAndJerkMeasurements
        
        return (dummyData, goalHistory)
    }
    
    // MARK: - Private Methods
    
    /// Returns the date corresponding to the specified number of weeks ago from today.
    ///
    /// - Parameter weeks: The number of weeks to subtract from the current date.
    /// - Returns: A `Date` representing the date that was `weeks` weeks ago.
    private static func dateWeeksAgo(_ weeks: Int) -> Date {
        Calendar.current.date(byAdding: .weekOfYear, value: -weeks, to: Date()) ?? Date()
    }
    
    /// Generates a dummy goal for a given movement with a specified target and start date,
    /// and wraps it in a `WeightLiftingGoalHistory` object.
    ///
    /// - Parameters:
    ///   - movement: The weightlifting movement (e.g., `.overheadSquat` or `.cleanAndJerk`) for which the goal is generated.
    ///   - target: The target weight for the goal.
    ///   - startDate: The date when the goal was set.
    /// - Returns: A `WeightLiftingGoalHistory` object containing the generated goal.
    private static func generateDummyGoalData(for movement: WeightliftingMovement, target: Double, startDate: Date) -> WeightLiftingGoalHistory {
        let goal = WeightLiftingGoal(
            id: UUID().uuidString,
            movement: movement,
            target: target,
            unit: .kg,
            createdDate: startDate
        )
        return WeightLiftingGoalHistory(id: UUID().uuidString, goals: [goal])
    }
    
    /// Generates an array of dummy measurements for a given movement.
    ///
    /// This function creates a series of measurements starting from a specified date,
    /// generating a fixed number of measurements with slight variations using a trend and random noise.
    /// For each measurement, it assigns a goal ID based on the provided goal histories where the goal's
    /// creation date is less than or equal to the measurement date.
    ///
    /// - Parameters:
    ///   - movement: The weightlifting movement for which measurements are generated.
    ///   - startDate: The start date for the measurements.
    ///   - measurementCount: The number of measurements to generate.
    ///   - goalHistories: An array of `WeightLiftingGoalHistory` used to determine the appropriate goal ID.
    /// - Returns: An array of `WeightLiftingMeasurement` objects representing the generated measurements.
    private static func generateDummyMeasurementData(for movement: WeightliftingMovement, startDate: Date, measurementCount: Int, withGoalHistory goalHistories: [WeightLiftingGoalHistory]) -> [WeightLiftingMeasurement] {
        
        let dummyValues: [Double] = (0..<measurementCount).map { index in
            let trend = Double(index) * 0.5
            let noise = Double.random(in: -0.1...0.1)
            let rawValue = 94.0 + trend + noise
            let roundedValue = (rawValue * 2).rounded() / 2.0
            return roundedValue
        }
        
        var measurements: [WeightLiftingMeasurement] = []
        let calendar = Calendar.current
        
        for i in 0..<measurementCount {
            guard let measurementDate = calendar.date(byAdding: .weekOfYear, value: i, to: startDate) else { continue }
            let assignedGoalId = goalHistories
                .flatMap { $0.goals }
                .filter { $0.movement == movement && $0.createdDate <= measurementDate }
                .sorted { $0.createdDate < $1.createdDate }
                .last?.id
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
    
}
