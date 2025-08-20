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
    @State var selection: AppScreen = .summary
    
    // MARK: - View
    
    var body: some View {
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
        .toolbarBackground(.pink, for: .tabBar)
        .tabBarMinimizeBehavior(.onScrollDown)
        .onAppear {
            send(.viewDidAppear)
        }
    }
    
    @ViewBuilder
    func tabContent(for appScreenTab: AppScreen) -> some View {
        switch appScreenTab {
        case .summary:
            summaryView
        case .activities:
            List(0..<100) { i in
                Text("activitie \(i)")
            }
        case .workout:
            workoutView
        default:
            EmptyView()
        }
    }

    @ViewBuilder
    var summaryView: some View {
        SummaryView(store: store.scope(
            state: \.summary,
            action: \.summary)
        )
    }
    
    @ViewBuilder
    var activitiesView: some View {
        ActivitiesView(store: store.scope(
            state: \.activities,
            action: \.activities)
        )
    }
    
    @ViewBuilder
    var workoutView: some View {
        WorkoutView(store: store.scope(
            state: \.workout,
            action: \.workout)
        )
    }
    
}
