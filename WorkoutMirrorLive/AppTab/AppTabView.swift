//
//  AppTabView.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 29/07/2025.
//

import ComposableArchitecture
import SwiftUI

@ViewAction(for: AppTabFeature.self)
struct AppTabView: View {
    
    // MARK: - Properties
    
    @Bindable var store: StoreOf<AppTabFeature>
    @State var selection: AppScreen = .live
    
    // MARK: - View
    
    var body: some View {
        TabView(selection: $store.selectedTab.sending(\.tabChanged)) {
            ForEach(store.tabs) { screen in
                tabContent(for: screen)
                    .tag(screen)
                ///.badge("new") ///.badge(1)
                    .tabItem {
                        Label(screen.title, systemImage: screen.image)
                    }
            }
        }
        .tabViewStyle(.sidebarAdaptable)
        .tabBarMinimizeBehavior(.onScrollDown)
        .tabViewBottomAccessory {
            TabViewBottomAccessoryPlacementView()
        }
        .onAppear {
            send(.viewDidAppear)
        }
    }
    
    @ViewBuilder
    func tabContent(for appScreenTab: AppScreen) -> some View {
        switch appScreenTab {
        case .live:
            liveView
        case .workout:
            List(0..<100) { i in
                Text("live \(i)")
            }
        case .person:
            personView
        default:
            EmptyView()
        }
    }
    
    @ViewBuilder
    var liveView: some View {
        LiveView(store: store.scope(
            state: \.live,
            action: \.live)
        )
        //        if let store = store.scope(state: \.live, action: \.live) {
        //            LiveView(store: store)
        //        } else {
        //            ProgressView()
        //                .onAppear {
        //                    send(.initLiveIfNeeded)
        //                }
        //        }
    }
    
    @ViewBuilder
    var personView: some View {
        PersonView(store: store.scope(
            state: \.person,
            action: \.person)
        )
    }
}

struct TabViewBottomAccessoryPlacementView: View {
    
    @Environment(\.tabViewBottomAccessoryPlacement) var placement
    
    var body: some View {
        switch placement {
        case .inline:
            HStack {
                Text("tu cos bedzie")
                Spacer()
                Button {
                    
                } label: {
                    Label("Play", systemImage: "square.and.arrow.down")
                }
                .buttonStyle(.glass)
            }
            .padding()
        case .expanded:
            expandedButton
            
        default:
            expandedButton
            
        }
    }
    private var expandedButton: some View {
        Button {
            
        } label: {
            HStack {
                Spacer()
                Text("tu cos bedzie")
                Spacer()
            }
        }
    }
}


//
//        TabView {
//            Tab(AppScreen.workout.title, systemImage: AppScreen.workout.image) {
//
//            }
//            Tab(AppScreen.live.title, systemImage: AppScreen.live.image) {
//
//            }
//            Tab(AppScreen.person.title, systemImage: AppScreen.person.image) {
//
//            }
//            Tab(role: .some(.search)) {
//
//            }
//        }
//
//truct BrowseTabExample: View {
//    @Environment(\.horizontalSizeClass) var sizeClass
//
//
//    @State var selection: MusicTab = .listenNow
//    @State var browseTabPath: [MusicTab] = []
//    @State var playlists = [Playlist("All Playlists"), Playlist("Running")]
//
//
//    var body: some View {
//            TabView(selection: $selection) {
//                Tab("Listen Now", systemImage: "play.circle", value: .listenNow) {
//                    ListenNowView()
//                }
//
//
//                Tab("Radio", systemImage: "dot.radiowaves.left.and.right", value: .radio) {
//                    RadioView()
//                }
//
//
//                Tab("Search", systemImage: "magnifyingglass", value: .search) {
//                    SearchDetailView()
//                }
//
//
//                Tab("Browse", systemImage: "list.bullet", value: .browse) {
//                    LibraryView(path: $browseTabPath)
//                }
//                .hidden(sizeClass != .compact)
//
//
//                TabSection("Library") {
//                    Tab("Recently Added", systemImage: "clock", value: MusicTab.library(.recentlyAdded)) {
//                        RecentlyAddedView()
//                    }
//
//
//                    Tab("Artists", systemImage: "music.mic", value: MusicTab.library(.artists)) {
//                        ArtistsView()
//                    }
//                }
//                .hidden(sizeClass == .compact)
//
//
//                TabSection("Playlists") {
//                    ForEach(playlists) { playlist in
//                        Tab(playlist.name, image: playlist.imafe, value: MusicTab.playlists(playlist)) {
//                            playlist.detailView()
//                        }
//                    }
//                }
//                .hidden(sizeClass == .compact)
//            }
//            .tabViewStyle(.sidebarAdaptable)
//            .onChange(of: sizeClass, initial: true) { _, sizeClass in
//                if sizeClass == .compact && selection.showInBrowseTab {
//                    browseTabPath = [selection]
//                    selection = .browse
//                } else if sizeClass == .regular && selection == .browse {
//                    selection = browseTabPath.last ?? .library(.recentlyAdded)
//                }
//            }
//        }
//    }
//}
