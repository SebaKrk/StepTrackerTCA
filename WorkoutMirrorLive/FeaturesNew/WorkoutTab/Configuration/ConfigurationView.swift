//
//  ConfigurationView.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 23/08/2025.
//

import ComposableArchitecture
import SwiftUI

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
                    //send(.viewDidAppear)
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
            
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Text("Tu cos bedzie")
                } label: {
                    menuInfoImage
                }
            }
        }
    }
    
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

//private var crossFitWorkoutButton: some View {
//    Button {
//
//    } label: {
//        Image(systemName: "figure")
//            .tint(.white)
//    }
//    .frame(width: 55, height: 55)
//    .glassEffect(.regular.interactive(true), in: .capsule)
//}
