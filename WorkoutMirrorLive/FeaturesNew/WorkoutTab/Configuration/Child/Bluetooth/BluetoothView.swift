//
//  BluetoothView.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 02/09/2025.
//

import Foundation
import ComposableArchitecture
import SwiftUI
import SharedModels
import CoreBluetooth

@ViewAction(for: BluetoothFeature.self)
struct BluetoothView: View {
    
    // MARK: - Properties
    var store: StoreOf<BluetoothFeature>
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("Scanning for devices...")
                Spacer()
                List(store.discoveredPeripherals, id: \.self) { peripheral in
                    VStack(alignment: .leading) {
                        HStack {
                            Text(peripheral.name ?? "Unknown Device")
                            Spacer()
                            //Text("State: \(peripheral.state.rawValue)")
                            Text("State: \(peripheral.state.rawValue)")
                        }
                        
                        Text("ID: \(peripheral.identifier.uuidString)")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
                Button {
                    send(.stopScanningButtonTapped)
                } label: {
                    Text("Stop")
                }
            }
            .toolbar {
                toolbarButtons
            }
            .onAppear {
                send(.viewDidAppear)
            }
        }
        
    }
    
    @ToolbarContentBuilder
    var toolbarButtons: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button {
                send(.closeButtonTapped)
            } label: {
                xMarkImage
            }
        }
    }
    
    private var xMarkImage: some View {
        Image(systemName: "xmark")
    }
}

