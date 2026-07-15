//
//  WeeklyRecurrenceTests.swift
//  SharedModels
//
//  Created by Sebastian Ściuba on 15/07/2026.
//

import Foundation
import Testing
@testable import SharedModels

@Suite("WeeklyRecurrence next occurrence")
struct WeeklyRecurrenceTests {

    /// Fixed gregorian calendar in a stable zone so weekday/time assertions are
    /// deterministic regardless of the machine running the tests.
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Warsaw")!
        return calendar
    }

    private func makeDate(_ year: Int, _ month: Int, _ day: Int, _ hour: Int, _ minute: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
    }

    @Test("Base still in the future is returned unchanged")
    func futureBaseUnchanged() {
        let base = makeDate(2026, 7, 15, 19, 30)   // Wed 15.07
        let now = makeDate(2026, 7, 10, 12, 0)     // before base
        #expect(WeeklyRecurrence.nextOccurrence(of: base, notBefore: now, calendar: calendar) == base)
    }

    @Test("Past base rolls forward one week, same weekday and time")
    func pastBaseRollsOneWeek() {
        let base = makeDate(2026, 7, 15, 19, 30)   // Wed 15.07 19:30
        let now = makeDate(2026, 7, 20, 8, 0)      // Mon 20.07
        let expected = makeDate(2026, 7, 22, 19, 30) // Wed 22.07 19:30
        let result = WeeklyRecurrence.nextOccurrence(of: base, notBefore: now, calendar: calendar)
        #expect(result == expected)
        #expect(calendar.component(.weekday, from: result) == 4) // Wednesday
    }

    @Test("Base exactly at now counts as the occurrence (not before)")
    func baseEqualToNow() {
        let base = makeDate(2026, 7, 15, 19, 30)
        #expect(WeeklyRecurrence.nextOccurrence(of: base, notBefore: base, calendar: calendar) == base)
    }

    @Test("Multi-week gap lands on the correct weekday")
    func multiWeekGap() {
        let base = makeDate(2026, 7, 15, 19, 30)   // Wed
        let now = makeDate(2026, 8, 5, 0, 0)       // Wed 05.08 (3 weeks later)
        let expected = makeDate(2026, 8, 5, 19, 30)
        let result = WeeklyRecurrence.nextOccurrence(of: base, notBefore: now, calendar: calendar)
        #expect(result == expected)
        #expect(calendar.component(.weekday, from: result) == 4) // Wednesday
    }

    @Test("Same-day but earlier time still rolls to next week")
    func sameDayLaterNowRollsForward() {
        let base = makeDate(2026, 7, 15, 19, 30)   // Wed 19:30
        let now = makeDate(2026, 7, 15, 20, 0)     // same Wed, 20:00 (class already passed)
        let expected = makeDate(2026, 7, 22, 19, 30)
        #expect(WeeklyRecurrence.nextOccurrence(of: base, notBefore: now, calendar: calendar) == expected)
    }
}
