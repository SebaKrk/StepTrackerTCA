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
import HealthHub

@ViewAction(for: BluetoothFeature.self)
struct BluetoothView: View {
    
    // MARK: - Properties
    @Bindable var store: StoreOf<BluetoothFeature>
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            rootView
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
    
    @ViewBuilder
    private var rootView: some View {
        switch store.bluetoothStatus {
        case .ready:
            devicesListView
        case .disconnected:
            Text("disconnected")
        case .unauthorized:
            Text("unauthorized")
        case .disabled:
            Text("disabled")
        case .unsupported:
            Text("unsupported")
            case .unknown:
                loadingView
        }
    }
    
    @ViewBuilder
    private var devicesListView: some View {
        if store.discoveredPeripherals.isEmpty {
            if store.isScanning {
                scanningView
            } else {
                VStack {
                    Spacer()
                    Text("No device detected.")
                    Spacer()
                    scanningButton
                }
            }
        } else {
            VStack {
                List(store.discoveredPeripherals, id: \.self) { peripheral in
                    deviceCell(peripheral)
                }
                scanningButton
            }
        }
    }
    
    private func deviceCell(_ peripheral: CBPeripheral) -> some View {
        VStack(alignment: .leading) {
            HStack {
                Text(peripheral.name ?? "Unknown Device")
                Spacer()
                Text("State: \(peripheral.state.rawValue)")
            }
            
            Text("ID: \(peripheral.identifier.uuidString)")
                .font(.footnote)
                .foregroundColor(.secondary)
        }
        .onTapGesture {
            send(.deviceTapped(peripheral)) 
        }
    }
  
    private var scanningButton: some View {
        Button {
            send(.scanningButtonTapped)
        } label: {
            Text(store.isScanning ? "Stop scanning" : "Start scanning")
        }
    }
    
    private var scanningView: some View {
        VStack {
            Spacer()
            ProgressView("Scanning...")
            Spacer()
            scanningButton
        }
        .transition(.opacity)
    }
    
    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView("Inicjalizuję Bluetooth...")
            Spacer()
        }
        .transition(.opacity)
    }
    
    private var xMarkImage: some View {
        Image(systemName: "xmark")
    }
}

//
//VStack {
//    Text("Scanning for devices...")
//    Spacer()
//    List(store.discoveredPeripherals, id: \.self) { peripheral in
//        VStack(alignment: .leading) {
//            HStack {
//                Text(peripheral.name ?? "Unknown Device")
//                Spacer()
//                //Text("State: \(peripheral.state.rawValue)")
//                Text("State: \(peripheral.state.rawValue)")
//            }
//            
//            Text("ID: \(peripheral.identifier.uuidString)")
//                .font(.footnote)
//                .foregroundColor(.secondary)
//        }
//    }
//    Spacer()
//    Button {
//        send(.stopScanningButtonTapped)
//    } label: {
//        Text("Stop")
//    }
//}
