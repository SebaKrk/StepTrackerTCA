//
//  ConfigurationView.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 23/08/2025.
//

import ComposableArchitecture
import SwiftUI
import HealthHub

@ViewAction(for: ConfigurationFeature.self)
struct ConfigurationView: View {
    
    // MARK: - Properties
    
    @Bindable var store: StoreOf<ConfigurationFeature>
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            rootView
                .navigationBarTitle(store.viewState.navTitle)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    toolbarButtons
                }
                .onAppear {
                    send(.viewDidAppear)
                }
                .sheet(
                    item: $store.scope(
                        state: \.destination?.bluetoothFeature,
                        action: \.destination.bluetoothFeature)
                ) { store in
                    BluetoothView(store: store)
                        .presentationDetents([.medium, .large])
                }
            
        }
    }
    
    // MARK: - SubView
    
    @ViewBuilder
    var rootView: some View {
        switch store.viewState {
        case .device:
            deviceView
        case .activity:
            activityView
        case .ready:
            readyView
        }
    }
    
    @ToolbarContentBuilder
    var toolbarButtons: some ToolbarContent {
        switch store.viewState {
        case .device:
            deviceToolBar
        case .activity:
            activityToolBar
        case .ready:
            readyToolBar
        }
    }
    
    private var deviceToolBar: some ToolbarContent {
        Group {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    send(.closeButtonTapped)
                } label: {
                    xMarkImage
                }
            }
            
            if store.bluetoothStatus == .ready  {
                ToolbarItem(placement: .topBarTrailing) {
                    if store.connectionBadge == 0 {
                        toolBarbBlueToothMenuButton
                    } else {
                        toolBarbBlueToothMenuButton
                            .badge(store.connectionBadge)
                    }
                }
            } else {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        bluetoothButtonStatus
                    } label: {
                        noConnectionImage
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var toolBarbBlueToothMenuButton: some View {
        Menu {
            availableDeviceNavButton
            Divider()
            heartRateSensorConnectStatus
            appleWatchConnectStatus
        } label: {
            connectionImage
        }
    }
    
    private var availableDeviceNavButton: some View {
        Button {
            send(.scanningBluetoothButtonTapped)
        } label: {
            Text("Bluetooth Devices")
        }
    }
    
    private var heartRateSensorConnectStatus: some View {
        Label {
            Text(store.isHeartRateConnected ? "connected" : "disconnected")
                .foregroundStyle(.white)
        } icon: {
            Image(systemName: "heart")
        }
    }
    
    private var appleWatchConnectStatus: some View {
        Label {
            Text(store.watchConnectivityStatus.rawValue)
        } icon: {
            Image(systemName: "applewatch.side.right")
        }
    }
    
    private var bluetoothButtonStatus: some View {
        Button {
            send(.scanningBluetoothButtonTapped)
        } label: {
            tabLabel("Bluetooth", store.bluetoothStatus, "bluetooth")
        }
    }
    
    private func tabLabel(_ title: String,
                          _ status: BluetoothStatus,
                          _ icon: String) -> some View {
        Label {
            Text("\(title) \(status.emoji) \(status.labelText)")
        } icon: {
            Image("bluetooth")
                .renderingMode(.template)
                .foregroundColor(.white)
        }
    }
    
    @ToolbarContentBuilder
    private var activityToolBar: some ToolbarContent {
        Group {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    send(.backToDeviceButtonTapped)
                } label: {
                    backwardImage
                }
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        
                    } label: {
                        Label {
                            Text("manage workout type")
                        } icon: {
                            Image(systemName: "chevron.right")
                        }
                    }
                } label: {
                    menuInfoImage
                }
            }
        }
    }
    
    private var readyToolBar: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button {
                if store.selectedDevice == .mirror {
                    send(.backToDeviceButtonTapped)
                } else {
                    send(.backToActivityButtonTapped)
                }
            } label: {
                backwardImage
            }
        }
    }
    
    private var xMarkImage: some View {
        Image(systemName: "xmark")
    }
    
    private var backwardImage: some View {
        Image(systemName: "chevron.backward")
    }
    
    private var menuInfoImage: some View {
        Image(systemName: "ellipsis")
    }
    
    private var noConnectionImage: some View {
        Image(systemName: "antenna.radiowaves.left.and.right.slash")
    }
    
    private var connectionImage: some View {
        Image(systemName: "antenna.radiowaves.left.and.right")
    }
    
    private var gearShapeImage: some View {
        ZStack(alignment: .bottomTrailing) {
            Image(systemName: "gearshape")
                .imageScale(.large)
            Circle()
                .fill(Color.red)
                .frame(width: 10, height: 10)
                .overlay(
                    Text("2") // <--- aktualizowac liczbe dostepnych sensorow
                        .font(.system(size: 7, weight: .bold))
                        .foregroundColor(.white)
                )
        }
    }
    
    private var deviceView: some View {
        DeviceView(store: store.scope(
            state: \.device,
            action: \.device)
        )
    }
    private var activityView: some View {
        ActivityPickerView(store: store.scope(
            state: \.activity,
            action: \.activity)
        )
    }
    
    private var readyView: some View {
        startButton
    }
    
    private var startButton: some View {
        Button {
            send(.startButtonTapped)
        } label: {
            Text("START")
                .bold()
                .tint(.white)
        }
        .frame(width: 75, height: 75)
        .glassEffect(.regular.interactive(true), in: .capsule)
    }
    
}
