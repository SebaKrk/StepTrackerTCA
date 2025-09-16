//
//  BluetoothView.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 02/09/2025.
//

import ComposableArchitecture
import CoreBluetooth
import SharedModels
import SwiftUI
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
                    bluetoothScanToolBar
                }
                .onAppear {
                    send(.viewDidAppear)
                }
        }
    }
    
    // MARK: - ToolBar
    
    @ToolbarContentBuilder
    var toolbarButtons: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button {
                send(.closeButtonTapped)
            } label: {
                xMarkImage
            }
            .buttonStyle(.glass)
        }
    }
    
    @ToolbarContentBuilder
    private var bluetoothScanToolBar: some ToolbarContent {
        ToolbarItemGroup(placement: .bottomBar) {
            Spacer()
            bluetoothScanButton
        }
    }
    
    // MARK: - SubView
    
    @ViewBuilder
    private var rootView: some View {
        switch store.bluetoothStatus {
        case .ready:
            readyView
                .onAppear {
                    send(.readyViewDidAppear)
                }
        case .disconnected:
            disconnectedView
        case .unauthorized:
            unauthorizedView
        case .disabled:
            disabledView
        case .unsupported:
            unsupportedView
        case .unknown:
            loadingView
        }
    }
    
    @ViewBuilder
    private var readyView: some View {
        List {
            Section("Connected Devices") {
                if !store.connectedDevices.isEmpty {
                    ForEach(store.connectedDevices, id: \.self) { device in
                        deviceRow(device)
                    }
                } else {
                    Text("You have no devices connected.")
                        .foregroundColor(.secondary)
                }
            }
            
            Section("Available Devices") {
                if store.availableDevices.isEmpty {
                    Text("No devices found.")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(store.availableDevices, id: \.self) { device in
                        deviceRow(device)
                    }
                }
            }
            
            if store.isScanning {
                Section {
                    EmptyView()
                } footer: {
                    HStack {
                        ProgressView()
                        Text("Scanning...")
                    }
                }
            }
        }
    }
    
    private func deviceRow(_ device: CBPeripheral) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text(device.name ?? "Unknown Device")
                    .font(.body)
                Text("ID: \(device.identifier.uuidString.prefix(14))...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            
            if device.state == .connecting || device.state == .disconnecting {
                ProgressView().id(UUID())
            } else {
                infoMenu(device)
            }
        }
        .onTapGesture {
            send(.deviceTapped(device))
        }
    }
    
    @ViewBuilder
    private func infoMenu(_ device: CBPeripheral) -> some View {
        Menu {
            if device.state == .connected {
                disconnectButton(device)
            } else if device.state == .disconnected {
                connectButton(device)
            }
        } label: {
            Image(systemName: "info.circle")
                .font(.headline)
        }
    }
    
    private func disconnectButton(_ device: CBPeripheral) -> some View {
        Button {
            send(.disconnectButtonTapped(device))
        } label: {
            Text("disconnect")
        }
    }
    
    private func connectButton(_ device: CBPeripheral) -> some View {
        Button {
            send(.deviceTapped(device))
        } label: {
            Text("connect")
        }
    }
    
    @ViewBuilder
    private var bluetoothScanButton: some View {
        Button {
            send(.scanningButtonTapped)
        } label: {
            Image(systemName: store.isScanning ? "stop" : "play")
                .tint(store.isScanning ? .red : .blue)
        }
        .buttonStyle(.borderedProminent)
    }
    
    private var disconnectedView: some View {
        BluetoothStatusView(bluetoothStatus: .disconnected, showActions: false)
    }
    
    private var unauthorizedView: some View {
        BluetoothStatusView(bluetoothStatus: .unauthorized, showActions: true) {
            send(.unauthorizedButtonTapped)
        }
    }
    
    private var disabledView: some View {
        BluetoothStatusView(bluetoothStatus: .disabled, showActions: true) {
            send(.disabledButtonTaped)
        }
    }
    
    private var unsupportedView: some View {
        BluetoothStatusView(bluetoothStatus: .unsupported, showActions: false)
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Initializing Bluetooth...")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var xMarkImage: some View {
        Image(systemName: "xmark")
    }
    
}
