//
//  TrainingReadinessTimeWindows.swift
//  HealthHub
//
//  Created by Sebastian Sciuba on 30/09/2025.
//

import Foundation

/// Defines standardized time windows for retrieving training readiness metrics.
///
/// Provides precise time ranges for health data queries, ensuring consistency across
/// different data types and avoiding ambiguous "last 24 hours" queries. Each window
/// is optimized for the specific physiological metric being measured.
///
/// ## Design Rationale
/// Training readiness should reflect the body's state at a specific point in time
/// (typically morning assessment). Using fixed time windows ensures:
/// - Consistent data collection across days
/// - Meaningful baseline comparisons
/// - Clinically relevant measurement periods
///
/// ## Usage
/// ```swift
/// let sleepWindow = TrainingReadinessTimeWindows.lastNightSleepWindow()
/// let samples = try await fetchSleepData(from: sleepWindow.start, to: sleepWindow.end)
/// ```
struct TrainingReadinessTimeWindows {
    
    /// Returns the time range for last night's sleep session.
    ///
    /// Defines a pragmatic window from yesterday evening to this morning that captures
    /// the primary sleep session. This 14-hour window (8 PM → 10 AM) is designed to
    /// reliably capture sleep data even with variations in actual sleep timing.
    ///
    /// - Returns: A tuple with start and end dates for last night's sleep window
    static func lastNightSleepWindow() -> (start: Date, end: Date) {
        let calendar = Calendar.current
        let now = Date()
        
        // End: 10 AM today
        let windowEnd = calendar.date(bySettingHour: 10, minute: 0, second: 0, of: now)!
        
        // Start: 8 PM yesterday (14 hours before 10 AM today)
        let windowStart = calendar.date(byAdding: .hour, value: -14, to: windowEnd)!
        
        return (start: windowStart, end: windowEnd)
    }
    
    /// Returns the time range for this morning's resting heart rate.
    ///
    /// Covers from midnight to 11 AM today to capture RHR measurements during sleep
    /// and early morning. RHR is typically measured by Apple Watch during sleep.
    ///
    /// - Returns: Tuple of (startDate, endDate) for the morning RHR window
    static func thisMorningRHRWindow() -> (start: Date, end: Date) {
        let calendar = Calendar.current
        let now = Date()
        
        // Start: midnight today (00:00)
        let startOfToday = calendar.startOfDay(for: now)
        
        // End: 11 AM today
        let endOfWindow = calendar.date(byAdding: .hour, value: 11, to: startOfToday)!
        
        return (startOfToday, endOfWindow)
    }
    
    /// Returns the time range for last night's HRV measurement.
    ///
    /// Covers from 8 PM yesterday to 10 AM today to capture HRV during sleep.
    /// HRV is most meaningful when measured during rest/sleep periods.
    ///
    /// - Returns: Tuple of (startDate, endDate) for the nighttime HRV window
    static func lastNightHRVWindow() -> (start: Date, end: Date) {
        let calendar = Calendar.current
        let now = Date()
        
        // End: 10 AM today
        let endOfWindow = calendar.date(bySettingHour: 10, minute: 0, second: 0, of: now)!
        
        // Start: 8 PM yesterday
        let startOfWindow = calendar.date(byAdding: .hour, value: -14, to: endOfWindow)!
        
        return (startOfWindow, endOfWindow)
    }
    
    /// Returns the time range for yesterday's full day (00:00 to 23:59).
    ///
    /// Used for measuring previous day's activity load, which impacts current readiness.
    ///
    /// - Returns: Tuple of (startDate, endDate) for yesterday's full day
    static func yesterdayFullDay() -> (start: Date, end: Date) {
        let calendar = Calendar.current
        let now = Date()
        
        // Start of yesterday (00:00)
        let yesterday = calendar.date(byAdding: .day, value: -1, to: now)!
        let startOfYesterday = calendar.startOfDay(for: yesterday)
        
        // End of yesterday (23:59:59)
        let endOfYesterday = calendar.date(byAdding: .day, value: 1, to: startOfYesterday)!
            .addingTimeInterval(-1)
        
        return (startOfYesterday, endOfYesterday)
    }
    
    /// Returns an array of date ranges for the last N nights.
    ///
    /// Used for calculating baseline averages over multiple sleep sessions.
    ///
    /// - Parameter nights: Number of previous nights to include
    /// - Returns: Array of (startDate, endDate) tuples, one per night
    static func lastNights(count nights: Int) -> [(start: Date, end: Date)] {
        let calendar = Calendar.current
        var ranges: [(Date, Date)] = []
        
        for dayOffset in 0..<nights {
            let referenceDate = calendar.date(byAdding: .day, value: -dayOffset, to: Date())!
            
            // Each night: 6 PM to 2 PM next day
            let endOfWindow = calendar.date(bySettingHour: 14, minute: 0, second: 0, of: referenceDate)!
            let startOfWindow = calendar.date(byAdding: .hour, value: -20, to: endOfWindow)!
            
            ranges.append((startOfWindow, endOfWindow))
        }
        
        return ranges
    }
    
    /// Returns an array of date ranges for the last N full days.
    ///
    /// Used for calculating baseline activity averages.
    ///
    /// - Parameter days: Number of previous days to include
    /// - Returns: Array of (startDate, endDate) tuples, one per day
    static func lastFullDays(count days: Int) -> [(start: Date, end: Date)] {
        let calendar = Calendar.current
        var ranges: [(Date, Date)] = []
        
        for dayOffset in 1...days {
            let targetDay = calendar.date(byAdding: .day, value: -dayOffset, to: Date())!
            let startOfDay = calendar.startOfDay(for: targetDay)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
                .addingTimeInterval(-1)
            
            ranges.append((startOfDay, endOfDay))
        }
        
        return ranges
    }
    
}
