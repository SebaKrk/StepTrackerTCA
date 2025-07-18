//
//  WorkoutCreatorView.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 04/07/2025.
//

import ComposableArchitecture
import SwiftUI
import SharedModels
import WorkoutKit


@ViewAction(for: WorkoutCreatorFeature.self)
struct WorkoutCreatorView: View {
    
    // MARK: - Properties
    
    @Bindable var store: StoreOf<WorkoutCreatorFeature>
    
    // MARK: - View
    
    var body: some View {
        NavigationStack {
            Group {
                formView
            }
            .navigationTitle("Workout Creator")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                toolbarButton
            }
            .sheet(isPresented: $store.isWorkoutTitleSheetPresented) {
                workoutTitleSheet
            }
            .sheet(item: $store.scope(state: \.destination?.openWorkoutActivityType,
                                      action: \.destination.openWorkoutActivityType)) { store in
                WorkoutActivityTypeView(store: store)
                    .presentationDetents([.medium])
            }
//            .sheet(item: $store.scope(state: \.warmUpConfiguration, action: \.warmUpConfiguration)) { store in
//                WorkoutActivityTypeView(store: store)
//            }
//            .sheet(item: $store.scope(state: \.coolDownConfiguration, action: \.coolDownConfiguration)) { store in
//                SessionConfigurationView(store: store)
//            }
//            .navigationDestination(item: $store.scope(state: \.destination?.openWodCreator,
//                                                      action: \.destination.openWodCreator)) { store in
//                WodCreatorView(store: store)
//            }
//            .navigationDestination(item: $store.scope(state: \.destination?.openWorkoutPreview,
//                                                      action: \.destination.openWorkoutPreview)) { store in
//                WorkoutPreviewView(store: store)
//                    .presentationDetents([.large, .medium])
//            }
        }
    }
    
    @ToolbarContentBuilder
    var toolbarButton: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) { cancelButton }
        if !store.wods.isEmpty {
            ToolbarItem(placement: .topBarTrailing) {
                previewButton
            }
        }
    }
    
    @ViewBuilder
    private var formView: some View {
        VStack {
            Form {
                workoutTitle
                workoutTypeContextPicker
                workoutLocationPicker
                warmUpButton
                createWodButton
                if !store.wods.isEmpty {
                    wodsView
                }
                coolDownButton
            }
        }
    }
    
    private var createWodButton: some View {
        Button {
            send(.wodSheetTapped)
        } label: {
            HStack {
                Text("Create WOD")
                    .foregroundColor(.primary)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
                
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    private var wodsView: some View {
        // TODO: - przejscie z uzupelnionymi danymi do WODu aby ewentualnie cos zmienic i zapisc
        List {
            ForEach(store.wods) { wod in
                Text(wod.name)
            }
        }
    }
    
    private var workoutTitle: some View {
        Button {
            send(.workoutTitleSheetTapped)
        } label: {
            HStack {
                Text("Title")
                    .foregroundColor(.primary)
                Spacer()
                Text(store.workoutTitle.isEmpty ? "Title" : store.workoutTitle)
                    .foregroundColor(.secondary)
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    @ViewBuilder
    private var workoutTitleSheet: some View {
        NavigationStack {
            Form {
                TextField("Workout title", text: $store.workoutTitle.sending(\.workoutTitleChanged))
                    .multilineTextAlignment(.leading)
            }
            .navigationTitle("Workout Title")
            .navigationBarTitleDisplayMode(.inline)
            .presentationDetents([.medium])
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        send(.workoutTitleSheetDismissed)
                    }
                }
            }
        }
        
    }
    
    @ViewBuilder
    private var workoutTypeContextPicker: some View {
//        Picker("Type", selection: $store.workoutActivityType.sending(\.selectedWorkoutActivityPickerChange)) {
//            Text("select workout").tag(nil as WorkoutActivityType?)
//            ForEach(store.availableWorkoutTypes, id: \.self) { item in
//                Text(item.title)
//                    .tag(item)
//            }
//        }
//        .pickerStyle(.navigationLink)
        
        Button {
            send(.workoutTypeButtonTaped)
        } label: {
            HStack {
                Text("Workout Type")
                    .foregroundColor(.primary)
                Spacer()
                if let type = store.workoutActivityType {
                    Text(type.title)
                        .foregroundColor(.secondary)
                }
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
                
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    @ViewBuilder
    private var workoutLocationPicker: some View {
        Picker("Location", selection: $store.workoutLocationType.sending(\.selectedWorkoutLocationPickerChange)) {
            Text("select workout").tag(nil as WorkoutLocationType?)
            ForEach(WorkoutLocationType.allCases, id: \.self) { item in
                Text(item.title)
                    .tag(item)
            }
        }
        .pickerStyle(.navigationLink)
    }

    private var warmUpButton: some View {
        Button {
            send(.openWarmUpSheetPresented)
        } label: {
            HStack {
                Text("Warm up")
                    .foregroundColor(.primary)
                Spacer()
                Text(store.warmUpDisplayText)
                    .foregroundColor(.secondary)
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var coolDownButton: some View {
        Button {
            send(.openCoolDownSheetPresented)
        } label: {
            HStack {
                Text("Cool Down")
                    .foregroundColor(.primary)
                Spacer()
                Text(store.coolDownDisplayText)
                    .foregroundColor(.secondary)
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Private
    
    private var cancelButton: some View {
        Button {
            send(.cancelButtonTapped)
        } label: {
            Text("Cancel")
        }
    }
    
    private var previewButton: some View {
        Button {
            send(.previewButtonTapped)
        } label: {
            Text("Show")
        }
    }
    
}

//import WorkoutKit
//CustomWorkout(
//    activity: HKWorkoutActivityType,
//    location: HKWorkoutSessionLocationType,
//    displayName: String?,
//    warmup: WorkoutStep?,
//    blocks: [IntervalBlock],
//    cooldown: WorkoutStep?
//)
