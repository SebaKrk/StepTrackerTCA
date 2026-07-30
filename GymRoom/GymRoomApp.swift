//
//  GymRoomApp.swift
//  GymRoom
//
//  Created by Sebastian Sciuba on 11/06/2026.
//

import AppDatabase
import ComposableArchitecture
import PeerMirror
import SwiftUI

@main
struct GymRoomApp: App {

    /// Root store dla całej app — `GymRoomRootFeature` wraps NavigationSplitView z 2 tabs:
    /// Classes (main hub, child ClassesListFeature) + History (placeholder, subtask D).
    let store: StoreOf<GymRoomRootFeature>

    init() {
        // Bootstrap SQLiteData PRZED init store — `@Dependency(\.defaultDatabase)`
        // w children reducers (gymClassClient → database.read/write) wymaga aktywnej
        // bazy. Migration v7_gymRoom wykonuje się tu po raz pierwszy: tworzy 3 tabele
        // (gymClassRecords, classSessionRecords, athleteSessionRecords) + indexy.
        prepareDependencies {
            do {
                try $0.bootstrapDatabase()
            } catch {
                fatalError("Database failed to initialize: \(error)")
            }
        }
        self.store = Store(initialState: GymRoomRootFeature.State()) {
            GymRoomRootFeature()
        }
    }

    var body: some Scene {
        WindowGroup {
            GymRoomRootView(store: store)
        }
    }
}
