//
//  SetWeightGoalView.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 24/01/2025.
//

import ComposableArchitecture
import SwiftUI

@ViewAction(for: SetWeightGoalFeature.self)
struct SetWeightGoalView: View {
    
    // MARK: - Properties
    
    @Bindable var store: StoreOf<SetWeightGoalFeature>
    
    // MARK: - View
    
    var body: some View {
        setWeightGoalBody
    }
    
    // MARK: - Subview
    
    private var setWeightGoalBody: some View {
        NavigationStack {
             setGoalBody
            .navigationTitle("Weight goal")
            .toolbar {
                toolbarButton
            }
            .alert(store: store.scope(state: \.$alert, action: \.alert))
        }
    }
    
    // MARK: - SubView
    
    @ToolbarContentBuilder
    var toolbarButton: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) { saveButton }
        ToolbarItem(placement: .topBarLeading) { dismissButton }
    }
    
    private var saveButton: some View {
        Button {
            send(.saveGoalButtonPressed)
        } label: {
            Text("Save")
        }
    }
    
    private var dismissButton: some View {
        Button {
            send(.dismissButtonPressed)
        } label: {
            Text("Dismiss")
        }
    }
    
    private var setGoalBody: some View {
        VStack {
            Form {
                datePicker
                setGoalTextField
            }
        }
    }
    
    var datePicker: some View {
        DatePicker("Date", selection: $store.addDataDate, displayedComponents: .date)
    }
    
    private var setGoalTextField: some View {
        HStack {
            Text("Weight Goal")
            Spacer()
            TextField("Goal Value", text: $store.value)
                .multilineTextAlignment(.trailing)
                .frame(width: 140)
                .keyboardType(.numberPad)
        }
    }
    
}
