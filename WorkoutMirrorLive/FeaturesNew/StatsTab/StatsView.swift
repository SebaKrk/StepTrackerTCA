//
//  StatsView.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 20/08/2025.
//

import ComposableArchitecture
import SwiftUI

@ViewAction(for: StatsFeature.self)
struct StatsView: View {
    
    // MARK: - Properties
    @Bindable var store: StoreOf<StatsFeature>
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            rootView
                .toolbar {
                    toolbarButton
                }
                .sheet(item: $store.scope(state: \.destination?.settings, action: \.destination.settings)) { store in
                    SettingsView(store: store)
                }
        }
        
    }
    
    var rootView: some View {
        Text("StatsFeature")
    }
    
    @ToolbarContentBuilder
    private var toolbarButton: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                send(.settingsButtonTapped)
            } label: {
                Image(systemName: "person")
            }
        }
    }
    
}
