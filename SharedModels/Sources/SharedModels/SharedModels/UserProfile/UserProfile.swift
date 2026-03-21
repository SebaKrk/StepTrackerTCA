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

    // MARK: - Init

    public init(
        id: UUID = UUID(),
        email: String = "",
        name: String = "",
        surname: String = "",
        nickname: String = ""
    ) {
        self.id = id
        self.email = email
        self.name = name
        self.surname = surname
        self.nickname = nickname
    }
}
