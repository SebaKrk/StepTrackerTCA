//
//  ActivityTabContent.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 12/01/2025.
//

import ComposableArchitecture
import SwiftUI

struct ActivityTabContent: View {
    
    // MARK: - Dependency
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    // MARK: - Properties
    
    @Bindable var store: StoreOf<ActivityFeature>
    
    // MARK: - Body
    
    var body: some View {
        if horizontalSizeClass == .compact {
            NavigationStack {
                ActivityView(store: store)
                    .navigationBarTitleDisplayMode(.inline)
            }
        } else {
            NavigationSplitView {
                NavigationStack {
                    ActivityView(store: store, withoutNavigationDestination: true)
                        .navigationBarTitleDisplayMode(.inline)
                }
            } detail: {
                NavigationStack {
                    if let store = store.scope(state: \.destination?.detailItem, action: \.destination.detailItem) {
                        ActivityDetailsView(store: store)
                    } else {
                        TabContentUnavailable()
                    }
                }
            }
        }
    }
    
}
