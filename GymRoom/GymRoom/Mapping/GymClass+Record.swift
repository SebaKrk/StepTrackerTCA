//
//  GymClass+Record.swift
//  GymRoom
//
//  Created by Sebastian Ściuba on 17/06/2026.
//

import AppDatabase
import Foundation

/// Mapping między domain model'em `GymClass` (UI layer) a persistence model'em
/// `GymClassRecord` (SQLite). Domain ma minimal API (UI consumes), Record ma
/// extra metadata (`updatedAt`, `ckRecordData` dla CloudKit sync).
///
/// **Separation rationale**: UI w GymRoom nie powinien importować `SQLiteData`
/// czy AppDatabase deeply — wymiana persistence layer (np. SQLite → Realm) nie
/// powinna kaskadować zmian w View / Reducer. Mapping helper to bridge.
extension GymClassRecord {

    /// Buduje Record z domain'u. `updatedAt` injected (zwykle `.now` przy save).
    /// `ckRecordData` zawsze `nil` przy create — set'owany przez future CloudKit
    /// sync engine (IPAD-0097).
    init(domain: GymClass, updatedAt: Date) {
        self.init(
            id: domain.id,
            name: domain.name,
            location: domain.location,
            scheduledAt: domain.scheduledAt,
            maxParticipants: domain.maxParticipants,
            createdAt: domain.createdAt,
            updatedAt: updatedAt,
            ckRecordData: nil
        )
    }

    /// Konwersja Record → Domain. Persistence-only fields (`updatedAt`, `ckRecordData`)
    /// dropped — UI ich nie potrzebuje.
    func toDomain() -> GymClass {
        GymClass(
            id: id,
            name: name,
            location: location,
            scheduledAt: scheduledAt,
            maxParticipants: maxParticipants,
            createdAt: createdAt
        )
    }
}
