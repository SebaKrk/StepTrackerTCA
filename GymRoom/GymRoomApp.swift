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
    /// `nil` when the database could not open — the reducers need a live one, so no store is built.
    let store: StoreOf<GymRoomRootFeature>?

    /// Why the database could not open; `nil` when the app started normally.
    private let databaseFailure: String?

    init() {
        // Bootstrap SQLiteData PRZED init store — `@Dependency(\.defaultDatabase)`
        // w children reducers (gymClassClient → database.read/write) wymaga aktywnej
        // bazy. Migration v7_gymRoom wykonuje się tu po raz pierwszy: tworzy 3 tabele
        // (gymClassRecords, classSessionRecords, athleteSessionRecords) + indexy.
        // A failed migration must leave an app that can say so, not one that dies on every launch.
        let failure = prepareDependencies { dependencies -> String? in
            do {
                try dependencies.bootstrapDatabase()
                return nil
            } catch {
                return String(describing: error)
            }
        }
        databaseFailure = failure
        store = failure == nil
            ? Store(initialState: GymRoomRootFeature.State()) { GymRoomRootFeature() }
            : nil
    }

    var body: some Scene {
        WindowGroup {
            if let store {
                GymRoomRootView(store: store)
            } else {
                DatabaseFailureView(
                    message: String(localized: "Close the app and open it again. If that does not help, contact us and include the code below."),
                    details: databaseFailure ?? ""
                )
            }
        }
    }
}
