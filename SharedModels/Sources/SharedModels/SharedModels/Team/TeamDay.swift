//
//  TeamDay.swift
//  SharedModels
//
//  Created by Sebastian Ściuba on 24/10/2026.
//

import Foundation

/// Day ids (`yyyy-MM-dd`) that name a group's daily plan.
public enum TeamDay {

    /// Id of the calendar day containing `date`.
    public static func id(for date: Date, calendar: Calendar) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", components.year ?? 0, components.month ?? 0, components.day ?? 0)
    }

    /// Ids of Monday…Sunday of the week containing `date`, whatever the locale's first weekday.
    public static func weekIds(containing date: Date, calendar: Calendar) -> [String] {
        var mondayFirst = calendar
        mondayFirst.firstWeekday = 2
        guard let week = mondayFirst.dateInterval(of: .weekOfYear, for: date) else {
            return [id(for: date, calendar: calendar)]
        }
        return (0..<7)
            .compactMap { offset in mondayFirst.date(byAdding: .day, value: offset, to: week.start) }
            .map { day in id(for: day, calendar: calendar) }
    }
}
