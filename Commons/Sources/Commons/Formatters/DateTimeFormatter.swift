//
//  DateTimeFormatter.swift
//  Commons
//

import Foundation

public struct DateTimeFormatter {

    /// Numeric date + 24h time: `dd.MM.yyyy HH:mm` (e.g. "16.05.2026 14:30").
    /// Locale-independent — no month names that flip between Polish/English
    /// depending on system language.
    public static let numericDateTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy HH:mm"
        return formatter
    }()
}
