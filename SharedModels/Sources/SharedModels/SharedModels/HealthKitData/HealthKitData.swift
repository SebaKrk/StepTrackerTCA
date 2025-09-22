//
//  HealthKitData.swift
//  SharedModels
//
//  Created by Sebastian Sciuba on 22/09/2025.
//

import Foundation

/// A data model representing health information retrieved from HealthKit.
///
/// `HealthKitData` serves as a standardized container for health-related measurements
/// and metrics obtained from Apple's HealthKit framework. This structure is designed
/// to encapsulate both the temporal aspect (when the measurement was taken) and the
/// quantitative value of various health data points.
///
/// ## Usage
/// Use this model to represent any health data retrieved from HealthKit, including:
/// - Body measurements (height, weight)
/// - Vital signs (heart rate, blood pressure)
/// - Activity metrics (steps, calories burned)
/// - Health characteristics (age, biological sex)`
/// 
public struct HealthKitData: Identifiable, Equatable {
    
    /// A unique identifier for each health data entry.
    ///
    /// This UUID is generated once when the instance is created and remains
    /// constant throughout the lifetime of the object, ensuring stable identity
    /// for SwiftUI lists and other UI components.
    public let id: UUID
    
    /// The date and time when the health measurement was recorded.
    public let date: Date
    
    /// The numerical value of the health measurement.
    ///
    /// The interpretation of this value depends on the context and unit of measurement.
    /// For example, this could represent kilograms for weight, beats per minute for heart rate,
    /// or meters for height.
    public let value: Double
    
    /// Creates a new health data instance.
    ///
    /// - Parameters:
    ///   - date: The date when the measurement was taken
    ///   - value: The numerical value of the measurement
    public init(date: Date, value: Double) {
        self.id = UUID()
        self.date = date
        self.value = value
    }
    
}
