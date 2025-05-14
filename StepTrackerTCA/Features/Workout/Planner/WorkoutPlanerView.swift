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
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                
            } label: {
                Text("Add")
            }
        }
        ToolbarItem(placement: .topBarLeading) {
            Button {
                
            } label: {
                Text("Cancel")
            }
        }
    }
    
    @ViewBuilder
    private var formView: some View {
        VStack {
            Form {
                datePicker
                workoutTypeContextPicker
                workoutLocationPicker
                energyGoalInputView
            }
            
            Button {
                send(.createWorkoutButtonTapped)
            } label: {
                Text("add")
            }
            
            if store.workoutPlan != nil {
                Button {
                    send(.showWorkoutPreview)
                } label: {
                    Label("Workout Preview", systemImage: "sparkle.magnifyingglass")
                }
                .workoutPreview(store.workoutPlan!, isPresented: $store.showPreview)
            }
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
            TextField("kcla", text: $store.energyGoalValueToAdd)
                .multilineTextAlignment(.trailing)
                .keyboardType(.decimalPad)
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
