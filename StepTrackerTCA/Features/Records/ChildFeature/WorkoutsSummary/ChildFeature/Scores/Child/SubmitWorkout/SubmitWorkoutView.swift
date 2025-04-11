//
//  SubmitWorkoutView.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 11/04/2025.
//

import ComposableArchitecture
import SwiftUI

@ViewAction(for: SubmitWorkoutFeature.self)
struct SubmitWorkoutView: View {
    
    // MARK: - Properties
    
    @Bindable var store: StoreOf<SubmitWorkoutFeature>
    
    // MARK: - View
    
    var body: some View {
        NavigationStack {
            Group {
                formView
            }
            .navigationTitle("Submit workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                toolbarButton
            }
        }
    }
    
    // MARK: - SubView
    
    @ViewBuilder
    private var formView: some View {
        VStack {
            Form {
                datePicker
                selectedWorkoutTypePicker
                if store.selectedMovement != nil {
                    measurementInputView
                }
            }
        }
    }
    
    @ToolbarContentBuilder
    var toolbarButton: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                send(.saveButtonPressed)
            } label: {
                Text("Save")
            }
        }
        ToolbarItem(placement: .topBarLeading) {
            Button {
                send(.dismissButtonPressed)
            } label: {
                Text("Cancel")
            }
        }
    }
    
    @ViewBuilder
    var datePicker: some View {
        DatePicker("Date", selection: $store.addDataDate, displayedComponents: .date)
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
            weightView
        case .fitness,.hero:
            timePicker
        case .cross:
            workoutInputView
        }
    }
    
    private var weightView: some View {
        HStack {
            TextField("Value", text: $store.valueToAdd)
                .multilineTextAlignment(.leading)
                .keyboardType(.decimalPad)
            Spacer()
            weightUnitContextPicker
        }
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
        .frame(width: 125)
    }
    
}
