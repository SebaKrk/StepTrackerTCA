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

@ViewAction(for: BluetoothFeature.self)
struct BluetoothView: View {
    
    // MARK: - Properties
    @Bindable var store: StoreOf<BluetoothFeature>
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            Text("BluetoothFeature")
                .toolbar {
                    toolbarButtons
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
