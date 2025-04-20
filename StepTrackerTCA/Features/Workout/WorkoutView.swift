//
//  WorkoutView.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 12/01/2025.
//

import ComposableArchitecture
import SwiftUI

@ViewAction(for: WorkoutFeature.self)
struct WorkoutView: View {
    
    // MARK: - Properties
    
    @Bindable var store: StoreOf<WorkoutFeature>
    
    // MARK: - View
    
    var body: some View {
        setGoalBody
            .onAppear {
                send(.viewDidAppear)
            }
    }
    
    private var saveButton: some View {
        Button {
            send(.saveGoalButtonPressed)
        } label: {
            Text("Save")
        }
    }
    
    private var setGoalBody: some View {
        Form {
            datePicker
            setGoalTextField
            HStack {
                Spacer()
                saveButton
            }
            goalValue
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
    
    private var goalValue: some View {
        HStack {
            Text("Weight Goal: ")
            Spacer()
            if let goalWeight = store.weightGoal {
                Text("\(goalWeight, format: .number) kg")
            } else {
                Text("Brak")
            }
        }
    }
    
}
