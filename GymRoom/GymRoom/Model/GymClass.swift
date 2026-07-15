//
//  GymClass.swift
//  GymRoom
//
//  Created by Sebastian Ściuba on 13/06/2026.
//

import Foundation

/// Schedule template dla klasy treningowej — entry w grafiku (Classes tab).
///
/// **Template pattern**: klasa nie ma `phase` ani `startedAt`/`endedAt`. To pure schedule
/// entry — re-usable (np. "Morning CrossFit" co wtorek). Każde uruchomienie tworzy
/// osobny `ClassSession` record w history (subtask B/C/D).
///
/// **Subtask A scope**: in-memory model. SQLiteData persistence w subtask B.
struct GymClass: Identifiable, Sendable, Equatable {
    let id: UUID
    var name: String              // mandatory ("Morning CrossFit")
    var location: String          // mandatory ("Sala 1" / address)
    var scheduledAt: Date?        // base date; for recurring = first occurrence
    var maxParticipants: Int      // BLE concurrent peer limit (Apple iPad ~8-16)
    var latitude: Double?         // geocoded from the MapKit address picker
    var longitude: Double?
    var isRecurring: Bool         // repeats weekly on scheduledAt's weekday+time
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        location: String,
        scheduledAt: Date? = nil,
        maxParticipants: Int = 8,
        latitude: Double? = nil,
        longitude: Double? = nil,
        isRecurring: Bool = false,
        createdAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.location = location
        self.scheduledAt = scheduledAt
        self.maxParticipants = maxParticipants
        self.latitude = latitude
        self.longitude = longitude
        self.isRecurring = isRecurring
        self.createdAt = createdAt
    }
}

/// Max BLE peripheral connections — Apple iOS docs: "subject to hardware constraints".
/// Practical limits: iPad Air ~8, iPad Pro M-series ~16. Safe default 8, upper bound 16.
enum GymClassCapacity {
    static let `default`: Int = 8
    static let lowerBound: Int = 1
    static let upperBound: Int = 16
}
