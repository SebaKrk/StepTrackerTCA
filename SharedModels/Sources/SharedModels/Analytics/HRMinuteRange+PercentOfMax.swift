//
//  HRMinuteRange+PercentOfMax.swift
//  SharedModels
//
//  Created by Sebastian Ściuba on 27/11/2026.
//

import Foundation

extension HRMinuteRange {

    /// Min–max BPM of this minute as a percent of the user's max HR; `nil` when max HR is unknown.
    public func percentOfMax(_ maxHeartRate: Double) -> ClosedRange<Int>? {
        guard maxHeartRate > 0 else { return nil }
        let low = Int((Double(minHR) / maxHeartRate * 100).rounded())
        let high = Int((Double(maxHR) / maxHeartRate * 100).rounded())
        return low...high
    }
}

extension Array where Element == HRMinuteRange {

    /// Charts sends the selection with ms precision, so match by calendar minute.
    public func range(at minute: Date) -> HRMinuteRange? {
        first { Calendar.current.isDate($0.minute, equalTo: minute, toGranularity: .minute) }
    }
}
