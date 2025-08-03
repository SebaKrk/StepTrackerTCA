//
//  WorkoutCreatorView.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 01/08/2025.
//

import ComposableArchitecture
import SwiftUI

@ViewAction(for: WorkoutCreatorFeature.self)
struct WorkoutCreatorView: View {
    
    // MARK: - Properties
    @Bindable var store: StoreOf<WorkoutCreatorFeature>
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            formView
                .navigationTitle("Create Workout")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    toolbarButton
                }
                .toolbar {
                    bottomToolbarButton
                }
                .fullScreenCover(item: $store.scope(state: \.destination?.workoutMirroringView,
                                                    action: \.destination.workoutMirroringView)) { store in
                    WorkoutMirroringView(store: store)
                }
        }
        
    }
    
    // MARK: - SubView
    
    @ToolbarContentBuilder
    private var toolbarButton: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            cancelButton
        }
    }
    
    @ToolbarContentBuilder
    var bottomToolbarButton: some ToolbarContent {
        ToolbarItemGroup(placement: .bottomBar) {
            Spacer()
            startButtonTaped
        }
    }
    
    @ViewBuilder
    private var formView: some View {
        VStack {
            Form {
                datePicker
            }
        }
    }
    
    var datePicker: some View {
        DatePicker("Date", selection: $store.addDataDate, displayedComponents: .date)
    }
    
    private var cancelButton: some View {
        Button {
            send(.cancelButtonTapped)
        } label: {
            Image(systemName: "xmark")
        }
    }
    
    private var startButtonTaped: some View {
        Button {
            send(.startButtonTaped)
        } label: {
            Image(systemName: "play")
        }
    }
    
}
