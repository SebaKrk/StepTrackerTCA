//
//  UserProfile.swift
//  SharedModels
//
//  Created by Sebastian Sciuba on 21/03/2026.
//

import Foundation

public struct UserProfile: Identifiable, Equatable, Codable, Sendable {

    // MARK: - Properties

    public let id: UUID
    public var email: String
    public var name: String
    public var surname: String
    public var nickname: String

    /// Account this profile belongs to, empty until the first sign-in.
    ///
    /// Everything that outlives the device is keyed by this, never by `id`,
    /// which is generated locally and differs after a reinstall.
    public var accountUid: String

    /// When the person first completed the welcome screen, `nil` before that.
    public var onboardedAt: Date?

    // MARK: - Init

    public init(
        id: UUID = UUID(),
        email: String = "",
        name: String = "",
        surname: String = "",
        nickname: String = "",
        accountUid: String = "",
        onboardedAt: Date? = nil
    ) {
        self.id = id
        self.email = email
        self.name = name
        self.surname = surname
        self.nickname = nickname
        self.accountUid = accountUid
        self.onboardedAt = onboardedAt
    }
}
