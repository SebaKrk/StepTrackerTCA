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

    public var id: UUID
    public var name: String
    public var surname: String
    public var nickname: String

    // MARK: - CloudKitSyncable

    public var createdAt: Date
    public var updatedAt: Date
    public var ckRecordData: Data?

    // MARK: - Init

    public init(
        id: UUID,
        name: String,
        surname: String,
        nickname: String,
        createdAt: Date,
        updatedAt: Date,
        ckRecordData: Data? = nil
    ) {
        self.id = id
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
            name: name,
            surname: surname,
            nickname: nickname
        )
    }
}
