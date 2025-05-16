//
//  WorkoutPlanerView.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 14/05/2025.
//

import ComposableArchitecture
import SwiftUI

@ViewAction(for: WorkoutPlanerFeature.self)
struct WorkoutPlanerView: View {
    
    // MARK: - Properties
    
    @Bindable var store: StoreOf<WorkoutPlanerFeature>
    
    // MARK: - View
    
    var body: some View {
        NavigationStack {
            Group {
                formView
            }
            .navigationTitle("Workout Planer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                toolbarButton
            }
        }
    }
    
    @ToolbarContentBuilder
    var toolbarButton: some ToolbarContent {
        if store.planerState == .add {
            ToolbarItem(placement: .topBarTrailing) { addButton }
        }
        ToolbarItem(placement: .topBarLeading) { cancelButton }
    }

    @ViewBuilder
    private var formView: some View {
        VStack {
            Form {
                datePicker
                workoutTypeContextPicker
                workoutLocationPicker
                energyGoalInputView
                addWorkoutForm
                saveWorkoutButton
            }
        }
    }

    @ViewBuilder
    var addWorkoutForm: some View {
        if let workoutPlan = store.workoutPlan, !store.seePreview {
            previewButton
            .workoutPreview(workoutPlan, isPresented: $store.showPreview)
            .onChange(of: store.showPreview, { oldValue, newValue in
                if newValue {
                    send(.userDidOpenPreview)
                } else {
                    send(.userDidClosePreview)
                }
            })
        }
    }
    
    @ViewBuilder
    var saveWorkoutButton: some View {
        if store.seePreview {
            saveButton
        }
    }
    
    var datePicker: some View {
        DatePicker("Date&Time",
                   selection: $store.dateAndTime,
                   displayedComponents: [.date, .hourAndMinute])
    }
    
    @ViewBuilder
    private var workoutTypeContextPicker: some View {
        Picker("Workout type", selection: $store.workoutActivityType.sending(\.selectedWorkoutActivityPickerChange)) {
            Text("select workout").tag(nil as WorkoutActivityType?)
            ForEach(WorkoutActivityType.allCases, id: \.self) { item in
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
    
    private var energyGoalInputView: some View {
        HStack {
            Text("Energy Goal")
            Spacer()
            TextField("kcla", text: $store.energyGoalValue)
                .multilineTextAlignment(.trailing)
                .keyboardType(.decimalPad)
        }
    }
    
    private var cancelButton: some View {
        Button {
            send(.cancelButtonTapped)
        } label: {
            Text("Cancel")
        }
    }
    
    private var addButton: some View {
        Button {
            send(.createWorkoutButtonTapped)
        } label: {
            Text("Add")
        }
    }
    
    private var previewButton: some View {
        HStack {
            Spacer()
            Button {
                send(.showWorkoutPreview)
            } label: {
                Text("Preview")
            }
        }
    }
    
    private var saveButton: some View {
        HStack {
            Spacer()
            Button {
                send(.saveScheduleWorkoutButtonTapped)
            } label: {
                Text("Save")
            }
        }
    }
    
}

#Preview {
    NavigationStack {
        WorkoutPlanerView(store: Store(initialState: WorkoutPlanerFeature.State(), reducer: {
            WorkoutPlanerFeature(service: DefaultWorkoutPlanerService())
        }))
    }
}
