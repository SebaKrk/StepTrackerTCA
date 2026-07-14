//
//  UserProfileRecord.swift
//  AppDatabase
//
//  Created by Sebastian Sciuba on 21/03/2026.
//

import Foundation
import SharedModels
import SQLiteData

// MARK: - Record

@Table
public struct UserProfileRecord: Identifiable, CloudKitSyncable {

    // MARK: - Properties

    /// Unique identifier — stable across updates, used for CloudKit sync
    public var id: UUID

    /// User's email address
    public var email: String

    /// User's first name
    public var name: String

    /// User's last name
    public var surname: String

    /// User's nickname
    public var nickname: String

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
        email: String,
        name: String,
        surname: String,
        nickname: String,
        createdAt: Date,
        updatedAt: Date,
        ckRecordData: Data? = nil
    ) {
        self.id = id
        self.email = email
        self.name = name
        self.surname = surname
        self.nickname = nickname
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.ckRecordData = ckRecordData
    }
}

// MARK: - Mapping

extension UserProfileRecord {

    public init(from profile: UserProfile, createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.init(
            id: profile.id,
            email: profile.email,
            name: profile.name,
            surname: profile.surname,
            nickname: profile.nickname,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    public func toDomain() -> UserProfile {
        UserProfile(
            id: id,
            email: email,
            name: name,
            surname: surname,
            nickname: nickname
        )
    }
}
