//
//  ActivitiesView.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 20/08/2025.
//

import ComposableArchitecture
import SwiftUI
import SharedModels
import HealthKit

@ViewAction(for: ActivitiesFeature.self)
struct ActivitiesView: View {
    
    // MARK: - Properties
    
    @Bindable var store: StoreOf<ActivitiesFeature>
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            switch store.viewState {
            case .loading:
                progressView
            case .success:
                rootView
            case .failed:
                Text("failed")
            }
        }

        .onAppear {
            send(.viewDidAppear)
        }
    }
    
    @ToolbarContentBuilder
    private var toolbarButton: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                ForEach(ActivitiesSortOption.allCases) { item in
                    Button {
                        send(.changeSortOption(item))
                    } label: {
                        Text(item.title)
                    }
                }
            } label: {
                Image(systemName: "line.3.horizontal.decrease.circle")
            }
        }
    }
    
    private var rootView: some View {
        VStack(spacing: 0) {
            trainingTabPicker
            switch store.context {
            case .personal:
                personalActivityView
            case .team:
                teamActivityView
            }
        }
        .navigationTitle("Activity")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !store.workouts.isEmpty {
                toolbarButton
            }
        }
    }
    
    private var trainingTabPicker: some View {
        Picker("trainingTabPicker", selection: $store.context.sending(\.selectedPickerChange)) {
            ForEach(ActivitiesFeature.TrainingTabContext.allCases, id: \.self) { item in
                Text(item.title)
                    .tag(item)
            }
        }
        .pickerStyle(.segmented)
        .padding([.leading, .trailing, .bottom], 6)
    }
    
    private var progressView: some View {
        ProgressView()
    }
    
    @ViewBuilder
    private var personalActivityView: some View {
        List {
            if store.workouts.isEmpty {
                emptyWorkoutsView
            } else {
                ForEach(store.workouts, id: \.uuid) { workout in
                    Text(workout.workoutActivityType.name)
                }
            }
        }
    }
    
    private var emptyWorkoutsView: some View {
        ContentUnavailableView(
            "No Workouts",
            systemImage: "figure.run",
            description: Text("No workouts found for the selected period. Make sure you have granted HealthKit access and recorded some workouts.")
        )
    }
    
    private var teamActivityView: some View {
        List {
            Text("teamActivityView")
        }
    }
    

}


//    var body: some View {
//        NavigationStack {
//            List(0..<100) { i in
//                Text("activitie \(i)")
//            }
//            .navigationTitle("ActivitiesFeature")
//            .navigationBarTitleDisplayMode(.inline)
//            .toolbar {
//                toolbarButtons
//            }
//            .sheet(item: $store.scope(state: \.destination?.settings, action: \.destination.settings)) { store in
//                SettingsView(store: store)
//            }
//            .sheet(item: $store.scope(state: \.destination?.animationTest, action: \.destination.animationTest)) { store in
//                AnimationView(store: store)
//            }
//        }
//    }
//
//    @ToolbarContentBuilder
//    var toolbarButtons: some ToolbarContent {
//        ToolbarItem(placement: .topBarTrailing) {
//            Button {
//
//            } label: {
//                Image(systemName: "apple.intelligence")
//            }
//        }
//
//        ToolbarItem(placement: .topBarLeading) {
//            Menu {
//                Button {
//                    send(.settingsButtonTapped)
//                } label: {
//                    Text("Settings")
//                }
//                Button {
//                    send(.activitiesButtonTapped)
//                } label: {
//                    Text("Animation")
//                }
//            } label: {
//                filterImage
//            }
//            .badge(store.badgeCount)
//        }
//    }
//
//    private var filterImage: some View {
//        Image(systemName: "line.3.horizontal.decrease")
//    }
//}
