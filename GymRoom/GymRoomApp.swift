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
    
    let store = Store(initialState: GymRoomFeature.State()) {
        GymRoomFeature()
    }

    var body: some Scene {
        WindowGroup {
            GymRoomView(store: store)
        }
    }
}
