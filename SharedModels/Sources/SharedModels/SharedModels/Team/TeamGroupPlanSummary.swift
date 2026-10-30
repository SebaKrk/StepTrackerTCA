//
//  TeamGroupPlanSummary.swift
//  SharedModels
//
//  Created by Sebastian Ściuba on 30/10/2026.
//

import Foundation

/// The group's most recent plan as stored on the group document, so the list shows it without reading the plan.
public struct TeamGroupPlanSummary: Equatable, Codable, Sendable {

    /// Day id of the plan (`yyyy-MM-dd`).
    public let day: String

    /// Plan title.
    public let title: String

    /// Points window in minutes.
    public let sessionMinutes: Int

    /// Name of the member who published it.
    public let authorName: String

    /// Members who posted a result to it.
    public let entryCount: Int

    public init(day: String, title: String, sessionMinutes: Int, authorName: String, entryCount: Int) {
        self.day = day
        self.title = title
        self.sessionMinutes = sessionMinutes
        self.authorName = authorName
        self.entryCount = entryCount
    }
}
