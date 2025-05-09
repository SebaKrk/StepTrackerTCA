//
//  AppTabView.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 11/01/2025.
//

import ComposableArchitecture
import SwiftUI

@ViewAction(for: AppTabFeature.self)
struct AppTabView: View {
    
    // MARK: - Properties
    
    @Bindable var store: StoreOf<AppTabFeature>
    
    // MARK: - View
    
    var body: some View {
        TabView(selection: $store.selectedTab.sending(\.tabChanged)) {
            ForEach(store.tabs) { screen in
                TabContent(for: screen)
                    .tag(screen as AppScreen?)
                    .tabItem { screen.label }
            }
        }
        .tint(.pink)
        .onAppear {
            send(.viewDidAppear)
        }
    }
    
    @ViewBuilder
    func TabContent(for appScreenTab: AppScreen) -> some View {
        switch appScreenTab {
        case .summary:
            DashboardView(store: store.scope(state: \.summaryTab, action: \.summaryTab))
        case .workout:
            WeightGoalTestView(store: store.scope(state: \.workoutTab, action: \.workoutTab))
        case .activity:
            ActivityTabContent(store: store.scope(state: \.activityTab, action: \.activityTab))
        case .fuel:
            Text("fuel")
        case .community:
            Text("community")
        case .settings:
            Text("settings")
        case .records:
            PersonDataView(store: store.scope(state: \.personDataTab, action: \.personDataTab))
        }
    }
    
}
