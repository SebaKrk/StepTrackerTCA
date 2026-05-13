//
//  Calendar+StartOfWeek.swift
//  SharedModels
//
//  Created by Sebastian Sciuba on 08/05/2026.
//

import Foundation

public extension Calendar {

    /// Returns the first day of the ISO week containing the given date.
    /// Uses `yearForWeekOfYear` + `weekOfYear` so it respects the calendar's
    /// `firstWeekday` and `minimumDaysInFirstWeek` settings.
    func startOfWeek(for date: Date) -> Date {
        let components = dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return self.date(from: components) ?? date
    }

}
