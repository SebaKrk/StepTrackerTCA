//
//  TrainingSessionRecord.swift
//  AppDatabase
//
//  Created by Sebastian Sciuba on 22/03/2026.
//

import Foundation
import SharedModels
import SQLiteData

// MARK: - Record

/// SQLite record for a training session plan.
///
/// Uses a hybrid storage strategy:
/// - Scalar fields (id, date, title, activity, location) → flat TEXT columns
/// - Nested structures (warmUp, workouts, coolDown) → JSON-encoded BLOB columns
///
/// This avoids complex multi-table joins while keeping the schema simple and CloudKit-compatible.
@Table
public struct TrainingSessionRecord: Identifiable, CloudKitSyncable {

    // MARK: - Properties

    /// Unique identifier — stable across updates, used for CloudKit sync
    public var id: UUID

    /// Date of the training session
    public var date: Date

    /// User-defined title of the session
    public var title: String

    /// Workout activity type — stored as rawValue String
    public var activity: String

    /// Workout location type — stored as rawValue String
    public var location: String

    /// JSON-encoded WarmUpSession — nil if session has no warm-up
    public var warmUpData: Data?

    /// JSON-encoded [WorkoutSessionNew] — main WODs of the session
    public var workoutsData: Data

    /// JSON-encoded CoolDownSession — nil if session has no cool-down
    public var coolDownData: Data?

    // MARK: - CloudKitSyncable

    /// Timestamp of record creation
    public var createdAt: Date

    /// Timestamp of last update — used for conflict resolution during iCloud sync
    public var updatedAt: Date

    /// Encoded CKRecord system fields (zone ID, record name, changeTag) — nil until first CloudKit sync
    public var ckRecordData: Data?

    // MARK: - Init

    public init(
        id: UUID,
        date: Date,
        title: String,
        activity: String,
        location: String,
        warmUpData: Data?,
        workoutsData: Data,
        coolDownData: Data?,
        createdAt: Date,
        updatedAt: Date,
        ckRecordData: Data? = nil
    ) {
        self.id = id
        self.date = date
        self.title = title
        self.activity = activity
        self.location = location
        self.warmUpData = warmUpData
        self.workoutsData = workoutsData
        self.coolDownData = coolDownData
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.ckRecordData = ckRecordData
    }
}

// MARK: - Mapping

extension TrainingSessionRecord {

    public init(from session: TrainingSession, createdAt: Date, updatedAt: Date) throws {
        let encoder = JSONEncoder()
        self.init(
            id: session.id,
            date: session.date,
            title: session.title,
            activity: session.activity.rawValue,
            location: session.location.rawValue,
            warmUpData: try session.warmUp.map { try encoder.encode($0) },
            workoutsData: try encoder.encode(session.workouts),
            coolDownData: try session.coolDown.map { try encoder.encode($0) },
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    public func toDomain() throws -> TrainingSession {
        let decoder = JSONDecoder()
        guard let activity = WorkoutActivityType(rawValue: activity) else {
            throw TrainingSessionRecordError.invalidActivityType(activity)
        }
        guard let location = WorkoutLocationType(rawValue: location) else {
            throw TrainingSessionRecordError.invalidLocationType(location)
        }
        return TrainingSession(
            id: id,
            date: date,
            title: title,
            activity: activity,
            location: location,
            warmUp: try warmUpData.map { try decoder.decode(WarmUpSession.self, from: $0) },
            workouts: try decoder.decode([WorkoutSessionNew].self, from: workoutsData),
            coolDown: try coolDownData.map { try decoder.decode(CoolDownSession.self, from: $0) }
        )
    }
}

// MARK: - Errors

enum TrainingSessionRecordError: Error {
    case invalidActivityType(String)
    case invalidLocationType(String)
}
