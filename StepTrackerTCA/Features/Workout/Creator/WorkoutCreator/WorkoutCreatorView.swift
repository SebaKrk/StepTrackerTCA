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
            .presentationDetents([.fraction(0.15)])
            .navigationDestination(item: $store.scope(state: \.destination?.openWodCreator,
                                                      action: \.destination.openWodCreator)) { store in
                WodCreatorView(store: store)
            }
        }
    }
    
    @ToolbarContentBuilder
    var toolbarButton: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) { cancelButton }
    }
    
    @ViewBuilder
    private var formView: some View {
        VStack {
            Form {
                workoutTitle
                workoutTypeContextPicker
                workoutLocationPicker
                warmUpButton
                wodView
                coolDownPicker
                if store.coolDownGoal == .timeLimit {
                    coolDownTimeLimit
                }
            }
        }
    }
    
    private var wodView: some View {
        Button {
            send(.wodSheetTapped)
        } label: {
            HStack {
                Text("Wod")
                    .foregroundColor(.primary)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
        }
        .buttonStyle(PlainButtonStyle())
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
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        send(.workoutTitleSheetDismissed)
                    }
                }
            }
        }
        .presentationDetents([.medium])
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
                    Text("\(store.warmUpGoalTime) minutes")
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
                        .tag(time)
                }
            }
            .pickerStyle(WheelPickerStyle())
            .frame(height: 125)
        }
    }
    
    @ViewBuilder
    private var coolDownPicker: some View {
        Picker("Cool down", selection: $store.coolDownGoal.sending(\.coolDownGoalChanged)) {
            Text("Select cool down").tag(nil as SimpleWorkoutGoal?)
            ForEach(SimpleWorkoutGoal.allCases, id: \.self) { item in
                Text(item.title)
                    .tag(item)
            }
        }
        .pickerStyle(.navigationLink)
    }
    
    private var coolDownTimeLimit: some View {
        VStack {
            Picker("Time", selection: $store.coolDownTime.sending(\.coolDownTimeChange)) {
                ForEach(store.availableTime, id: \.self) { time in
                    Text("\(time)").tag(time)
                }
            }
            .pickerStyle(WheelPickerStyle())
            .frame(height: 150)
            HStack {
                Spacer()
                Button {
                    print("aaa")
                } label: {
                    Text("Done")
                }
            }
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
