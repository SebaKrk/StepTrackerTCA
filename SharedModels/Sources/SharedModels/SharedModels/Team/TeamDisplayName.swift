//
//  TeamDisplayName.swift
//  SharedModels
//
//  Created by Sebastian Ściuba on 25/10/2026.
//

import Foundation

/// Name other group members see — same order as GymRoom.
public enum TeamDisplayName {

    /// Nickname, then first name, then a stable "Athlete-XXX" from the account id.
    public static func make(nickname: String?, name: String?, uid: String) -> String {
        if let nickname, !nickname.isEmpty {
            return nickname
        }
        if let name, !name.isEmpty {
            return name
        }
        return "Athlete-" + uid.prefix(3).uppercased()
    }
}
