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

    /// Start of the day named by `id`; `nil` when `id` is not `yyyy-MM-dd`.
    public static func date(for id: String, calendar: Calendar) -> Date? {
        let parts = id.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return nil }
        return calendar.date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2]))
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
