//
//  ActivitiesView.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 20/08/2025.
//

import ComposableArchitecture
import SwiftUI

@ViewAction(for: ActivitiesFeature.self)
struct ActivitiesView: View {
    
    // MARK: - Properties
    @Bindable var store: StoreOf<ActivitiesFeature>
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            List(0..<100) { i in
                Text("activitie \(i)")
            }
            .navigationTitle("ActivitiesFeature")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                toolbarButton
            }
            .sheet(item: $store.scope(state: \.destination?.settings, action: \.destination.settings)) { store in
                SettingsView(store: store)
            }
            .sheet(item: $store.scope(state: \.destination?.animationTest, action: \.destination.animationTest)) { store in
                AnimationView(store: store)
            }
        }
    }
    
    @ToolbarContentBuilder
    var toolbarButton: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Button {
                    send(.settingsButtonTapped)
                } label: {
                    Text("Settings")
                }
                Button {
                    send(.activitiesButtonTapped)
                } label: {
                    Text("Animation")
                }
            } label: {
                filterImage
            }
            .badge(store.badgeCount)
        }
    }
    
    private var filterImage: some View {
        Image(systemName: "line.3.horizontal.decrease")
    }
}
