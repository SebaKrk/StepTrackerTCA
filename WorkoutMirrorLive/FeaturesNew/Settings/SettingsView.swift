//
//  SettingsView.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 22/08/2025.
//

import Foundation
import ComposableArchitecture
import SwiftUI

@ViewAction(for: SettingsFeature.self)
struct SettingsView: View {
    
    // MARK: - Properties
    @Bindable var store: StoreOf<SettingsFeature>
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            rootView
                .toolbar {
                    toolbarButton
                }
        }
        
    }
    
    var rootView: some View {
        Text("SettingsView")
    }
    
    @ToolbarContentBuilder
    private var toolbarButton: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                send(.xMarkButtonTapped)
            } label: {
                Image(systemName: "xmark")
            }
        }
    }
    
}
