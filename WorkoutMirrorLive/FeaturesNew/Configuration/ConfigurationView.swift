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
    
    @ViewBuilder
    var rootView: some View {
        switch store.viewState {
        case .device:
            deviceView
        case .activity:
            crossFitWorkoutButton
        case .ready:
            Text("ready")
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
        
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Text("Tu cos bedzie")
            } label: {
                menuInfoImage
            }
            
        }
    }
    
    private var xMarkImage: some View {
        Image(systemName: "xmark")
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
    
    private var crossFitWorkoutButton: some View {
        Button {
            
        } label: {
            Image(systemName: "figure")
                .tint(.white)
        }
        .frame(width: 55, height: 55)
        .glassEffect(.regular.interactive(true), in: .capsule)
    }

}





