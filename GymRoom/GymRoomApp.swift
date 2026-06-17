//
//  GymRoomApp.swift
//  GymRoom
//
//  Created by Sebastian Sciuba on 11/06/2026.
//

import ComposableArchitecture
import PeerMirror
import SwiftUI

@main
struct GymRoomApp: App {

    /// Root store dla całej app — `GymRoomRootFeature` wraps NavigationSplitView z 2 tabs:
    /// Classes (main hub, child ClassesListFeature) + History (placeholder, subtask D).
    let store = Store(initialState: GymRoomRootFeature.State()) {
        GymRoomRootFeature()
    }

    var body: some Scene {
        WindowGroup {
            GymRoomRootView(store: store)
        }
    }
}
