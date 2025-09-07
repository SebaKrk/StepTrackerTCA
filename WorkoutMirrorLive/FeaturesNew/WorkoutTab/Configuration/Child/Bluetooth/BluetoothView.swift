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
            Text("Disconnected")
        case .unauthorized:
            Text("Unauthorized - Open Settings")
        case .disabled:
            Text("Bluetooth Disabled")
        case .unsupported:
            Text("Bluetooth Unsupported")
        case .unknown:
            loadingView
        }
    }
    
    @ViewBuilder
    private var devicesListView: some View {
        VStack {
            // Sekcja połączonych urządzeń
            if let connectedDevice = store.connectedDevice {
                connectedDevicesSection(connectedDevice)
            } else {
                Text("Brak polaczonch urzadzen")
            }
            
            // Sekcja dostępnych urządzeń
            availableDevicesSection
            
            // Przycisk skanowania na dole
            scanningButton
                .padding()
        }
    }
    
    /// Sekcja pokazująca połączone urządzenie
    private func connectedDevicesSection(_ device: CBPeripheral) -> some View {
        VStack(alignment: .leading) {
            Text("Connected Device")
                .font(.headline)
                .padding(.horizontal)
            
            deviceCell(device, isConnected: true)
                .padding(.horizontal)
            
            Divider()
        }
    }
    
    /// Sekcja pokazująca dostępne urządzenia
    @ViewBuilder
    private var availableDevicesSection: some View {
        if store.availableDevices.isEmpty {
            if store.isScanning {
                scanningView
            } else {
                emptyDevicesView
            }
        } else {
            VStack(alignment: .leading) {
                Text("Available Devices")
                    .font(.headline)
                    .padding(.horizontal)
                
                List(store.availableDevices, id: \.self) { peripheral in
                    deviceCell(peripheral, isConnected: false)
                }
                .listStyle(PlainListStyle())
            }
        }
    }
    
    /// Komórka urządzenia - różna dla połączonych i dostępnych
    private func deviceCell(_ peripheral: CBPeripheral, isConnected: Bool) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                VStack(alignment: .leading) {
                    Text(peripheral.name ?? "Unknown Device")
                        .font(.body)
                        .fontWeight(isConnected ? .semibold : .regular)
                    
                    Text("ID: \(peripheral.identifier.uuidString.prefix(8))...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isConnected {
                    Text("CONNECTED")
                        .font(.caption)
                        .foregroundColor(.green)
                        .fontWeight(.semibold)
                } else {
                    Text("TAP TO CONNECT")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            
            if isConnected && !store.connectionStatus.isEmpty {
                Text(store.connectionStatus)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
        .onTapGesture {
            if !isConnected {
                send(.deviceTapped(peripheral))
            }
        }
    }
    
    /// Przycisk start/stop skanowania
    private var scanningButton: some View {
        Button {
            send(.scanningButtonTapped)
        } label: {
            Text(store.isScanning ? "Stop Scanning" : "Start Scanning")
                .foregroundColor(.white)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(store.isScanning ? Color.red : Color.blue)
        .cornerRadius(10)
    }
    
    /// Widok podczas skanowania
    private var scanningView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Scanning for devices...")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 100)
    }
    
    /// Widok gdy brak urządzeń
    private var emptyDevicesView: some View {
        VStack(spacing: 16) {
            Image(systemName: "antenna.radiowaves.left.and.right")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            
            Text("No devices found")
                .font(.body)
                .foregroundColor(.secondary)
            
            Text("Tap 'Start Scanning' to search for heart rate monitors")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 150)
    }
    
    /// Widok ładowania
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
