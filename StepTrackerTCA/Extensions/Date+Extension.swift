//
//  Date+Extension.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 06/01/2025.
//

import Foundation

/// An extension for the `Date` type to provide additional functionality.
extension Date {
    
    /// Returns the integer representation of the weekday for the current date.
    ///
    /// - The value corresponds to the weekday in the current calendar.
    /// - Example:
    ///     - 1: Sunday (in most Gregorian calendars)
    ///     - 2: Monday
    ///     - 7: Saturday
    ///
    /// - Note: This uses the `Calendar.current` instance to calculate the weekday
    ///   and respects the user's current locale and settings.
    ///
    /// - Returns: An `Int` representing the day of the week.
    var weekdayInt: Int {
        Calendar.current.component(.weekday, from: self)
    }
    
}
