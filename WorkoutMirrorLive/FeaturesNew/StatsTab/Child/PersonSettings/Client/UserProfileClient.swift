//
//  UserProfileClient.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 21/03/2026.
//

import AppDatabase
import Dependencies
import Foundation
import SharedModels
import SQLiteData

struct UserProfileClient: Sendable {
    var save: @Sendable (UserProfile) async throws -> Void
    var fetch: @Sendable () async throws -> UserProfile?
}

extension DependencyValues {
    var userProfileClient: UserProfileClient {
        get { self[UserProfileClientKey.self] }
        set { self[UserProfileClientKey.self] = newValue }
    }
}

private enum UserProfileClientKey: DependencyKey {

    static let liveValue: UserProfileClient = {
        @Dependency(\.defaultDatabase) var database

        return UserProfileClient(
            save: { profile in
                @Dependency(\.date.now) var now
                try await database.write { db in
                    let draft = UserProfileRecord.Draft(
                        id: profile.id,
                        email: profile.email,
                        name: profile.name,
                        surname: profile.surname,
                        nickname: profile.nickname,
                        createdAt: now,
                        updatedAt: now
                    )
                    try UserProfileRecord.upsert { draft }.execute(db)
                }
            },
            fetch: {
                try await database.read { db in
                    try UserProfileRecord
                        .order { $0.updatedAt.desc() }
                        .fetchOne(db)?
                        .toDomain()
                }
            }
        )
    }()

    static var testValue: UserProfileClient {
        UserProfileClient(
            save: unimplemented("UserProfileClient.save"),
            fetch: unimplemented("UserProfileClient.fetch")
        )
    }
}
