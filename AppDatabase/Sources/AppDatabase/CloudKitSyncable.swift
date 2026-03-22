//
//  CloudKitSyncable.swift
//  AppDatabase
//
//  Created by Sebastian Sciuba on 21/03/2026.
//

import Foundation

// FURTKA iCloud — protokół dokumentuje intent syncowalnych rekordów.
//
// Kolumny MUSZĄ być płaskie (nie nested struct) — SQLite wymaga flat columns
// do efektywnego ORDER BY updatedAt / WHERE updatedAt > lastSync.
//
// ckRecordData: zakodowane system fields CKRecord (zone ID, record name, changeTag).
// nil = rekord jeszcze nie zsynchronizowany z CloudKit.
//
// TODO: IOS-00071-iCloud — Ref: pfw-sqlite-data → references/icloud.md
public protocol CloudKitSyncable {
    var createdAt: Date { get set }
    var updatedAt: Date { get set }
    var ckRecordData: Data? { get set }
}
