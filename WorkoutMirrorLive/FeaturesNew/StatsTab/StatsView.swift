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
                .onAppear {
                    send(.viewDidAppear)
                }
                .fullScreenCover(item: $store.scope(state: \.destination?.personSettings,
                                                    action: \.destination.personSettings)) { store in
                    PersonSettingsView(store: store)
                }
        }
    }
    
    var rootView: some View {
        Text("StatsView")
    }
    
    @ToolbarContentBuilder
    private var toolbarButton: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                send(.personButtonTapped)
            } label: {
                Image(systemName: "person")
            }
        }
    }
    
}
