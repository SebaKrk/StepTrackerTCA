//
//  AppTab.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 19/08/2025.
//

import SwiftUI

enum AppTabTEST: CaseIterable {
    case live, workout, person
    
    var title: String {
        switch self {

        case .live: return "Live"
        case .workout: return "Workout"
        case .person: return "Workout"
        }
    }
    
    var icon: String {
        switch self {
        case .live: return "figure"
        case .workout: return "figure.run"
        case .person: return "figure.run"
        }
    }
}

struct AppTabRootView: View {
    let tab: AppTabTEST
    
    var body: some View {
        NavigationStack {
            content
                .navigationTitle(tab.title)
                .navigationBarTitleDisplayMode(.large)
        }
    }
    
    @ViewBuilder
    private var content: some View {
        switch tab {
//        case .boat:
//            Text("BoatConditionView()")
//        case .sea:
//            List(0..<100) { i in
//                Text("live \(i)")
//            }
//        case .compose:
//            Text("ComposeView()")
//            
        case .live:
            List(0..<100) { i in
                Text("live \(i)")
            }
            
        case .workout:
            Text("figure.run")
            
        case .person:
            Text("figure.run")
        }
    }
}


struct AppTabViewTest: View {
    
    @State private var selectedTab: AppTab = .live
    
    var body: some View {
        TabView(selection: $selectedTab) {
            ForEach(AppTabTEST.allCases, id: \.self) { tab in
                Tab(value: tab, role: tab == .workout ? .search : nil) {
                    AppTabRootView(tab: tab)
                } label: {
                    if tab == .workout {
                        Label(tab.title, systemImage: tab.icon)
                            .foregroundStyle(.pink, .pink)
                            .buttonStyle(.borderedProminent)
//                            .tint(.red)
//                            .foregroundStyle(.white)
//                            .background(.red, in: Circle())
//
//                            .foregroundStyle(.red)
//                            .foregroundStyle(.pink, .primary)
//                            .tint(.blue)
//                            .matchedTransitionSource(id: "compose-tab", in: composeNamespace)
                    } else {
                        Label(tab.title, systemImage: tab.icon)
                    }
                }
            }
        }
        .toolbarBackground(.red, for: .tabBar)
//        .toolbarColorScheme(.dark, for: .tabBar)
//        .foregroundStyle(.pink, .yellow)
//        .tint(.yellow)
        .tabBarMinimizeBehavior(.onScrollDown)
    }
    //        @Bindable var router = router
    //        TabView(selection: $router.selectedTab) {
    //            ForEach(AppTab.allCases, id: \.self) { tab in
    //                Tab(value: tab) {
    //                    AppTabRootView(tab: tab)
    //                } label: {
    //                    if tab == .compose {
    //                        Label(tab.title, systemImage: tab.icon)
    ////                            .matchedTransitionSource(id: "compose-tab",
    ////                                                     in: composeNamespace)
    //                    } else {
    //                        Label(tab.title, systemImage: tab.icon)
    //                    }
    //                }
    //            }
    //        TabView {
    //            Tab("Boat", systemImage: "sailboat"){
    //                Text("BoatConditionView")
    //            }
    //            Tab("Sea", systemImage: "water.waves"){
    //                Text("WaterConditionView")
    //
    //            }
    //
    //            Tab(role: .some(.search)) {
    //
    //            }
    //        }
    //
    //        .onChange(of: router.selectedTab) { oldTab, newTab in
    //            if newTab == .compose {
    //                withAnimation { showComposeOverlay = true }
    //                router.selectedTab = oldTab
    //            }
    //        }
    
    //    }
}
