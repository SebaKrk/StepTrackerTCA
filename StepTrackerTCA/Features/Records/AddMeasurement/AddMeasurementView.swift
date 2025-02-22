//
//  AddMeasurementView.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 18/02/2025.
//

import ComposableArchitecture
import SwiftUI

@ViewAction(for: AddMeasurementFeature.self)
struct AddMeasurementView: View {
    
    // MARK: - Properties
    
    @Bindable var store: StoreOf<AddMeasurementFeature>
    
    // MARK: - View
    
    var body: some View {
        NavigationStack {
            Group {
                formView
            }
            .navigationTitle("Add Measurement")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                toolbarButton
            }
            .alert(store: store.scope(state: \.$alert, action: \.alert))
        }
    }
    
    // MARK: - SubView
    
    @ToolbarContentBuilder
    var toolbarButton: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                send(.addButtonTapped)
            } label: {
                Text("Add")
            }
        }
        ToolbarItem(placement: .topBarLeading) {
            Button {
                send(.cancelButtonTapped)
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
                selectedWorkoutTypePicker
                if store.workoutType != nil {
                    measurementInputView
                    workoutDescriptionView
                }
            }
        }
    }
    
    var datePicker: some View {
        DatePicker("Date", selection: $store.addDataDate, displayedComponents: .date)
        
    }
    
    @ViewBuilder
    private var workoutTypeContextPicker: some View {
        Picker("Workout type", selection: $store.workoutType.sending(\.selectedWorkoutPickerChange)) {
            Text("select workout").tag(nil as WorkoutType?)
            ForEach(WorkoutType.allCases, id: \.self) { item in
                Text(item.title)
                    .tag(item)
            }
        }
        .pickerStyle(.navigationLink)
    }
    
    @ViewBuilder
    private var selectedWorkoutTypePicker: some View {
        switch store.workoutType {
        case .weightlifting:
            weightliftingTypeContextPicker
        case .strength:
            strengthTypeContextPicker
        case .fitness:
            fitnessTypeContextPicker
        case .cross:
            crossTypeContextPicker
        case .hero:
            heroTypeContextPicker
        case .none:
            EmptyView()
        }
    }
    
    @ViewBuilder
    private var weightliftingTypeContextPicker: some View {
        Picker("Weightlifting", selection: $store.weightliftingMovement.sending(\.selectedWeightliftingMovementPickerChange)) {
            Text("select").tag(nil as WeightliftingMovement?)
            ForEach(WeightliftingMovement.allCases, id: \.self) { item in
                Text(item.title)
                    .tag(item)
            }
        }
        .pickerStyle(.navigationLink)
    }
    
    @ViewBuilder
    private var strengthTypeContextPicker: some View {
        Picker("Strength", selection: $store.strengthMovement.sending(\.selectedStrengthMovementPickerChange)) {
            Text("select").tag(nil as StrengthMovement?)
            ForEach(StrengthMovement.allCases, id: \.self) { item in
                Text(item.title)
                    .tag(item)
            }
        }
        .pickerStyle(.navigationLink)
    }
    
    @ViewBuilder
    private var fitnessTypeContextPicker: some View {
        Picker("Fitness", selection: $store.fitnessMovement.sending(\.selectedFitnessMovementPickerChange)) {
            Text("select").tag(nil as FitnessMovement?)
            ForEach(FitnessMovement.allCases, id: \.self) { item in
                Text(item.title)
                    .tag(item)
            }
        }
        .pickerStyle(.navigationLink)
    }
    
    @ViewBuilder
    private var crossTypeContextPicker: some View {
        Picker("Cross", selection: $store.crossMovement.sending(\.selectedCrossMovementPickerChange)) {
            Text("select").tag(nil as CrossMovement?)
            ForEach(CrossMovement.allCases, id: \.self) { item in
                Text(item.title)
                    .tag(item)
            }
        }
        .pickerStyle(.navigationLink)
    }
    
    @ViewBuilder
    private var heroTypeContextPicker: some View {
        Picker("Hero WOD", selection: $store.heroMovement.sending(\.selectedHeroMovementPickerChange)) {
            Text("select").tag(nil as HeroMovement?)
            ForEach(HeroMovement.allCases, id: \.self) { item in
                Text(item.title)
                    .tag(item)
            }
        }
        .pickerStyle(.navigationLink)
    }
    
    @ViewBuilder
    private var measurementInputView: some View {
        switch store.workoutType {
        case .weightlifting, .strength:
            weightInputView
        case .fitness,.hero:
            timePicker
        case .cross:
            workoutInputView
        case .none:
            EmptyView()
        }
    }
    
    private var weightInputView: some View {
        HStack {
            TextField("Value", text: $store.valueToAdd)
                .multilineTextAlignment(.leading)
                .keyboardType(.decimalPad)
            Spacer()
            weightUnitContextPicker
        }
    }
    
    @ViewBuilder
    private var weightUnitContextPicker: some View {
        Picker("WeightUnit", selection: $store.weightUnit.sending(\.selectedWeightUnitPickerChange)) {
            ForEach(WeightUnit.allCases, id: \.self) { item in
                Text(item.label)
                    .tag(item)
            }
        }
        .pickerStyle(.segmented)
        .frame(width: 100)
    }
    
    private var workoutInputView: some View {
        HStack {
            TextField("Value", text: $store.crossValueToAdd)
                .multilineTextAlignment(.leading)
                .keyboardType(.decimalPad)
            Spacer()
            workoutUnitContextPicker
        }
    }
    
    @ViewBuilder
    private var workoutUnitContextPicker: some View {
        Picker("WorkoutUnit", selection: $store.workoutUnit.sending(\.selectedWorkoutUnitPickerChange)) {
            ForEach(WorkoutUnit.allCases, id: \.self) { item in
                Text(item.label)
                    .tag(item)
            }
        }
        .pickerStyle(.segmented)
        .frame(width: 75)
    }
    
    var timePicker: some View {
        HStack {
            Text("Time score")
            Spacer()
            DurationPicker(duration: $store.timeInterval)
                .foregroundStyle(.secondary)
                .frame(width: 160, alignment: .trailing)
        }
    }
    
    @ViewBuilder
    private var workoutDescriptionView: some View {
        if let workoutType = store.workoutType {
            DisclosureGroup("Workout description", isExpanded: $store.descriptionIsExpanded) {
                Text(workoutDescription(for: workoutType))
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        }
    }

    private func workoutDescription(for workoutType: WorkoutType) -> String {
        switch workoutType {
        case .weightlifting:
            return store.weightliftingMovement?.description ?? "Select a movement to see its description."
        case .strength:
            return store.strengthMovement?.description ?? "Select a movement to see its description."
        case .fitness:
            return store.fitnessMovement?.description ?? "Select a movement to see its description."
        case .cross:
            return store.crossMovement?.description ?? "Select a movement to see its description."
        case .hero:
            return store.heroMovement?.description ?? "Select a movement to see its description."
        }
    }
    
}
