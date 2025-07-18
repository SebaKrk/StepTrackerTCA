//
//  WorkoutActivityTypeView.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 18/07/2025.
//

import ComposableArchitecture
import SwiftUI

@ViewAction(for: WorkoutActivityTypeFeature.self)
struct WorkoutActivityTypeView: View {
    
    // MARK: - Properties
    
    @Bindable var store: StoreOf<WorkoutActivityTypeFeature>
    
    // MARK: - View
    
    var body: some View {
        NavigationStack {
            rootView
                .navigationTitle("Activity Type")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { toolbarButton }
        }
    }
    
    private var rootView: some View {
            workoutTypeSimpleList
    }
    
   
    @ViewBuilder
    private var workoutTypeSimpleList: some View {
        List(selection: $store.workoutActivityType.sending(\.workoutActivityTypeChange)) {
            ForEach(store.availableWorkoutTypes, id: \.self) { item in
                HStack {
                    Text(item.title)
                        .tag(item)
                    Spacer()
                    if store.workoutActivityType == item {
                        Image(systemName: "checkmark")
                            .foregroundColor(.pink)
                    }
                }
            }
        }
        .environment(\.editMode, .constant(.active))
    }
    
    @ToolbarContentBuilder
    var toolbarButton: some ToolbarContent {
        ToolbarItem(placement: .confirmationAction) { saveButton }
    }
    
    private var saveButton: some View {
        Button {
            send(.saveButtonTapped)
        } label: {
            Text("Save")
        }
    }
}



//    @ViewBuilder
//    private var workoutTypeContextPicker: some View {
//        Picker("Type", selection: $store.workoutActivityType.sending(\.internalAction.workoutActivityTypeChange)) {
//            Text("select workout").tag(nil as WorkoutActivityType?)
//            ForEach(store.availableWorkoutTypes, id: \.self) { item in
//                Text(item.title)
//                    .tag(item)
//            }
//        }
//        .pickerStyle(.navigationLink)
//    }
