//
//  AppTabNewView.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 20/08/2025.
//

import ComposableArchitecture
import SwiftUI

@ViewAction(for: AppTabNewFeature.self)
struct AppTabNewView: View {
    
    // MARK: - Properties
    
    @Bindable var store: StoreOf<AppTabNewFeature>
    
    // MARK: - View
    
    var body: some View {
        tabView
            .tabBarMinimizeBehavior(.onScrollDown)
            .tint(.primary)
            .toolbarBackground(.pink, for: .tabBar)
            .onAppear {
                send(.viewDidAppear)
            }
            .sheet(
                item: $store.scope(
                    state: \.destination?.workoutConfiguration,
                    action: \.destination.workoutConfiguration)
            ) { store in
                ConfigurationView(store: store)
                    .interactiveDismissDisabled(true)
                    .presentationDetents([.medium])
            }
            .fullScreenCover(
                item: $store.scope(
                    state: \.destination?.session,
                    action: \.destination.session)
            ) { store in
                SessionView(store: store)
            }
    }
    
    private var tabView: some View {
        TabView(selection: $store.selectedTab.sending(\.tabChanged)) {
            ForEach(store.tabs) { tab in
                Tab(value: tab, role: tab == .workout ? .search : nil) {
                    tabContent(for: tab)
                } label: {
                    if tab == .workout {
                        Label(tab.title, systemImage: tab.image)
                            .foregroundStyle(.pink, .pink)
                            .buttonStyle(.borderedProminent)
                    } else {
                        Label(tab.title, systemImage: tab.image)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    func tabContent(for appScreenTab: AppScreen) -> some View {
        switch appScreenTab {
        case .stats:
            statsView
        case .activities:
            activitiesView
        case .workout:
            EmptyView()
        case .sharing:
            Text("sharing")
        default:
            ProgressView()
        }
    }
    
    @ViewBuilder
    var statsView: some View {
        StatsView(store: store.scope(
            state: \.stats,
            action: \.stats)
        )
    }
    
    @ViewBuilder
    var activitiesView: some View {
        ActivitiesView(store: store.scope(
            state: \.activities,
            action: \.activities)
        )
    }
    
    //    @ViewBuilder
    //    var workoutView: some View {
    //        WorkoutView(store: store.scope(
    //            state: \.workout,
    //            action: \.workout)
    //        )
    //    }
    
}
