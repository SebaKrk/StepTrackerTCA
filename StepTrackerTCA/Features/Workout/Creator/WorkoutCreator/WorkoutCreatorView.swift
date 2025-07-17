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
            .sheet(isPresented: $store.isWarmUpSheetPresented) {
                warmUpPickerSheet
            }
            .sheet(isPresented: $store.isCoolDownSheetPresented) {
                coolDownPickerSheet
            }
            .navigationDestination(item: $store.scope(state: \.destination?.openWodCreator,
                                                      action: \.destination.openWodCreator)) { store in
                WodCreatorView(store: store)
            }
            .navigationDestination(item: $store.scope(state: \.destination?.openWorkoutPreview,
                                                      action: \.destination.openWorkoutPreview)) { store in
                WorkoutPreviewView(store: store)
            }
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
        Picker("Type", selection: $store.workoutActivityType.sending(\.selectedWorkoutActivityPickerChange)) {
            Text("select workout").tag(nil as WorkoutActivityType?)
            ForEach(store.availableWorkoutTypes, id: \.self) { item in
                Text(item.title)
                    .tag(item)
            }
        }
        .pickerStyle(.navigationLink)
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
                if store.warmupGoal == .open {
                    Text(store.warmupGoal.title)
                        .foregroundColor(.secondary)
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                        .font(.caption)
                } else {
                    Text("\(store.warmUpGoalTime ?? 0 ) minutes")
                        .foregroundColor(.secondary)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var warmUpPickerSheet: some View {
        NavigationStack {
            Form {
                Section {
                    warmUpPicker
                    if store.warmupGoal == .timeLimit {
                        warmUpTimeLimit
                    }
                }
            }
            .navigationTitle("Warm Up")
            .navigationBarTitleDisplayMode(.inline)
            .presentationDetents([.medium])
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        send(.openWarmUpSheetPresented)
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        send(.openWarmUpSheetPresented)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var warmUpPicker: some View {
        List {
            Section("Warm up") {
                ForEach(SimpleWorkoutGoal.allCases, id: \.self) { item in
                    Button {
                        send(.warmupGoalButtonTapped(item))
                    } label: {
                        HStack {
                            Text(item.title)
                            Spacer()
                            if store.warmupGoal == item {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.pink)
                            }
                        }
                        .padding()
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    .listRowInsets(EdgeInsets())
                }
            }
        }
    }
    
    private var warmUpTimeLimit: some View {
        VStack {
            Picker("Time", selection: $store.warmUpGoalTime.sending(\.warmupTimeChange)) {
                ForEach(store.availableTime, id: \.self) { time in
                    Text("\(time)")
                        .tag(time as Int?)
                }
            }
            .pickerStyle(WheelPickerStyle())
            .frame(height: 125)
            .onChange(of: store.warmUpGoalTime) { oldValue, newValue in
                     print("Picker changed: \(oldValue) -> \(newValue)")
                 }
        }
    }
    
    private var coolDownButton: some View {
        Button {
            send(.openCoolDownSheetPresented)
        } label: {
            HStack {
                Text("Cool Down")
                    .foregroundColor(.primary)
                Spacer()
                if store.coolDownGoal == .open {
                    Text(store.coolDownGoal.title)
                        .foregroundColor(.secondary)
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                        .font(.caption)
                } else {
                    Text("\(store.coolDownTime ?? 0) minutes")
                        .foregroundColor(.secondary)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var coolDownPickerSheet: some View {
        NavigationStack {
            Form {
                Section {
                    coolDownPicker
                    if store.coolDownGoal == .timeLimit {
                        coolDownTimeLimit
                    }
                }
            }
            .navigationTitle("Cool Down")
            .navigationBarTitleDisplayMode(.inline)
            .presentationDetents([.medium])
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        send(.openCoolDownSheetPresented)
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        send(.openCoolDownSheetPresented)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var coolDownPicker: some View {
        List {
            Section("Cool Down") {
                ForEach(SimpleWorkoutGoal.allCases, id: \.self) { item in
                    Button {
                        send(.coolDownButtonTapped(item))
                    } label: {
                        HStack {
                            Text(item.title)
                            Spacer()
                            if store.coolDownGoal == item {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.pink)
                            }
                        }
                        .padding()
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    .listRowInsets(EdgeInsets())
                }
            }
        }
    }
    
    private var coolDownTimeLimit: some View {
        VStack {
            Picker("Time", selection: $store.coolDownTime.sending(\.coolDownTimeChange)) {
                ForEach(store.availableTime, id: \.self) { time in
                    Text("\(time)")
                        .tag(time)
                }
            }
            .pickerStyle(WheelPickerStyle())
            .frame(height: 125)
        }
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
