//
//  SetEditGoalView.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 15/02/2025.
//

import ComposableArchitecture
import SwiftUI

@ViewAction(for: SetEditGoalFeature.self)
struct SetEditGoalView: View {
    
    // MARK: - Properties
    
    @Bindable var store: StoreOf<SetEditGoalFeature>
    
    // MARK: - View
    
    var body: some View {
        NavigationStack {
            Group {
                formView
            }
            .navigationTitle("Set new Goals")
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
                movementContextPicker
                weightView
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
    private var movementContextPicker: some View {
        Picker("Movement", selection: $store.movementType.sending(\.selectedMovementPickerChange)) {
            Text("select movement").tag(nil as WeightliftingMovement?)
            ForEach(WeightliftingMovement.allCases, id: \.self) { item in
                Text(item.title)
                    .tag(item)
            }
        }
        .pickerStyle(.navigationLink)
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
    
}
