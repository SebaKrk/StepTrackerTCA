//
//  Destination.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 12/09/2025.
//

import ComposableArchitecture

/// Implementation of `ConfigurationFeature` destination
extension ConfigurationFeature {
    
    @Reducer
    enum Destination {
        /// BluetoothFeature destination dla skanowania i łączenia urządzeń
        case bluetoothFeature(BluetoothFeature)
    }
}
