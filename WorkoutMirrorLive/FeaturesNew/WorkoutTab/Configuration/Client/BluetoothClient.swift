//
//  BluetoothClient.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 02/09/2025.
//

import ComposableArchitecture
import Foundation

struct BluetoothClient {

}

extension DependencyValues {
    var bluetoothClient: BluetoothClient {
        get { self[BluetoothClientKey.self] }
        set { self[BluetoothClientKey.self] = newValue }
    }
}

private enum BluetoothClientKey: DependencyKey {
    static let liveValue: BluetoothClient = {
        
        @Dependency(\.centralManager) var manager
        
        return BluetoothClient { type in
            
        }
    }
}
