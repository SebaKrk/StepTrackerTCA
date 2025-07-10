//
//  WodCreatorView.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 04/07/2025.
//

import ComposableArchitecture
import SwiftUI
import SharedModels

@ViewAction(for: WodCreatorFeature.self)
struct WodCreatorView: View {
    
    // MARK: - Properties
    
    @Bindable var store: StoreOf<WodCreatorFeature>
    
    // MARK: - View
    
    var body: some View {
        VStack {
            Form {
                Section {
                    wodTitle
                    wodType
                    wodTimer
                    wodRounds
                }
                Section {
                    addExerciseButton
                    if store.addExercise {
                        exerciseTypePicker
                        repsView
                        weightView
                        infoButton
                    }
                    Button {
                        send(.addToExercises)
                    } label: {
                        HStack {
                            Spacer()
                            Text("add")
                        }
                    }
                } header: {
                    Text("Exercises")
                }
                
                Section {
                    exerciseList
                }
            }
        }
        .navigationTitle("Create WOD")
        .toolbar { toolbarButton }
        .sheet(isPresented: $store.isWodTitleSheetPresented) {
            wodTitleSheet
        }
        .presentationDetents([.fraction(0.15)])
        .sheet(isPresented: $store.isWodInfoSheetPresented) {
            wodInfoSheet
        }
    }
    
    @ToolbarContentBuilder
    private var toolbarButton: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) { saveButton }
    }
    
    private var wodTitle: some View {
        Button {
            send(.wodTitleSheetTapped)
        } label: {
            HStack {
                Text("Title")
                    .foregroundColor(.primary)
                Spacer()
                Text(store.wodTitle.isEmpty ? "WOD 1" : store.wodTitle)
                    .foregroundColor(.secondary)
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    

    @ViewBuilder
    private var wodTitleSheet: some View {
        NavigationStack {
            Form {
                TextField("WOD workout title", text: $store.wodTitle.sending(\.wodTitleChanged))
                    .multilineTextAlignment(.leading)
            }
            .navigationTitle("Workout title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        send(.wodTitleSheetDismissed)
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
    
    @ViewBuilder
    private var wodType: some View {
        Button {
            send(.workoutTypeTapped)
        } label: {
            HStack {
                Text("Type")
                    .foregroundColor(.primary)
                Spacer()
                Text(store.selectedExerciseWorkoutType.displayName)
                    .foregroundColor(.secondary)
                Image(systemName: store.isExerciseWorkoutTypePresented ? "chevron.up" : "chevron.down")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
        }
        .buttonStyle(PlainButtonStyle())
        
        if store.isExerciseWorkoutTypePresented {
            wodExerciseWorkoutTypePicker
        }
    }
     
    @ViewBuilder
    private var wodExerciseWorkoutTypePicker: some View {
        Picker("WOD Workout type picker", selection: $store.selectedExerciseWorkoutType.sending(\.exerciseWorkoutType)) {
            ForEach(ExerciseWorkoutType.allCases, id: \.self) { type in
                Text(type.displayName)
                    .tag(type)
            }
        }
        .pickerStyle(WheelPickerStyle())
        .frame(height: 150)
        .transition(.opacity.combined(with: .scale))
        .animation(.easeInOut(duration: 0.3), value: store.isExerciseWorkoutTypePresented)
    }
    
    
    @ViewBuilder
    var wodTimer: some View {
        Toggle("Timer", isOn: $store.isDurationPickerPresented)
        if store.isDurationPickerPresented {
            Button {
                send(.durationPickerTapped)
            } label: {
                HStack {
                    Text("Time Cap")
                        .foregroundColor(.primary)
                    Spacer()
                    Text("\(store.selectedDuration) min")
                        .foregroundColor(.secondary)
                    Image(systemName: store.isDurationPickerToggle ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            if store.isDurationPickerToggle {
                wodTimerPicker
            }
        }
    }
    
    private var wodTimerPicker: some View {
        Picker("WOD timer picker", selection: $store.selectedDuration.sending(\.durationChanged)) {
            ForEach(store.availableDurations, id: \.self) { duration in
                Text("\(duration) min")
                    .tag(duration)
            }
        }
        .pickerStyle(WheelPickerStyle())
        .frame(height: 150)
        .transition(.opacity.combined(with: .scale))
        .animation(.easeInOut(duration: 0.3), value: store.isDurationPickerPresented)
    }
    
    @ViewBuilder
    var wodRounds: some View {
        Button {
            send(.roundsPickerTapped)
        } label: {
            HStack {
                Text("Rounds")
                    .foregroundColor(.primary)
                Spacer()
                Text("\(store.selectedRounds) rounds")
                    .foregroundColor(.secondary)
                Image(systemName: store.isRoundsPickerPresented ? "chevron.up" : "chevron.down")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
        }
        .buttonStyle(PlainButtonStyle())
        
        if store.isRoundsPickerPresented {
            wodRoundsPicker
        }
    }
    
    private var wodRoundsPicker: some View {
        Picker("Rounds", selection: $store.selectedRounds.sending(\.roundsChange)) {
            ForEach(store.availableRounds, id: \.self) { duration in
                Text("\(duration)")
                    .tag(duration)
            }
        }
        .pickerStyle(WheelPickerStyle())
        .frame(height: 150)
        .transition(.opacity.combined(with: .scale))
        .animation(.easeInOut(duration: 0.3), value: store.isRoundsPickerPresented)
    }
    
    private var addExerciseButton: some View {
        Button {
            send(.addExerciseTapped)
        } label: {
            HStack {
                Text("add exercise")
                    .foregroundColor(.primary)
                Spacer()
                Image(systemName: "plus")
                    .foregroundColor(.pink)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var exerciseTypePicker: some View {
        Picker("Exercise", selection: $store.selectedExerciseType.sending(\.exerciseTypeChange)) {
            ForEach(ExerciseType.allCases, id: \.self) { exercise in
                Text(exercise.displayName)
                    .tag(exercise)
            }
        }
        .pickerStyle(.navigationLink)
    }
    
    
    @ViewBuilder
    var repsView: some View {
        Button {
            send(.repsPickerTapped)
        } label: {
            HStack {
                Text("Reps")
                    .foregroundColor(.primary)
                Spacer()
                Text("\(store.selectedReps) reps")
                    .foregroundColor(.secondary)
                Image(systemName: store.isRepsPickerPresented ? "chevron.up" : "chevron.down")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
        }
        .buttonStyle(PlainButtonStyle())
        
        if store.isRepsPickerPresented {
            repsPicker
        }
    }
    
    private var repsPicker: some View {
        Picker("Reps", selection: $store.selectedReps.sending(\.repsChange)) {
            ForEach(store.availableReps, id: \.self) { rep in
                Text("\(rep)")
                    .tag(rep)
            }
        }
        .pickerStyle(WheelPickerStyle())
        .frame(height: 150)
        .transition(.opacity.combined(with: .scale))
        .animation(.easeInOut(duration: 0.3), value: store.isRepsPickerPresented)
    }
    
    private var weightView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle("Weight", isOn: $store.isWeightViewPresented)
            
            if store.isWeightViewPresented {
                VStack(spacing: 8) {
                    HStack {
                        Text("Mężczyzna")
                            .foregroundColor(.secondary)
                        Spacer()
                        TextField("kg", text: $store.weightMen.sending(\.weightMenChange))
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.decimalPad)
                    }
                    .padding(4)
                    
                    HStack {
                        Text("Kobieta")
                            .foregroundColor(.secondary)
                        Spacer()
                        TextField("kg", text: $store.weightWomen.sending(\.weightWomenChange))
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.decimalPad)
                            .frame(width: 150)
                    }
                    .padding(4)
                }
            }
        }
    }
    
    private var infoButton: some View {
        Button {
            send(.wodInfoButtonTapped)
        } label: {
            HStack {
                Text("Info")
                    .foregroundColor(.primary)
                Spacer()
                Text(store.info.isEmpty ? "add info" : store.info)
                    .foregroundColor(.secondary)
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    @ViewBuilder
    private var wodInfoSheet: some View {
        NavigationStack {
            Form {
                TextEditor(text: $store.info.sending(\.wodInfoChanged))
                    .frame(minHeight: 100)
                    .overlay(
                        Group {
                            if store.info.isEmpty {
                                VStack {
                                    HStack {
                                        Text("WOD workout description...")
                                            .foregroundColor(.secondary)
                                            .padding(.horizontal, 4)
                                            .padding(.vertical, 8)
                                        Spacer()
                                    }
                                    Spacer()
                                }
                            }
                        }
                    )
            }
            .navigationTitle("Extra info")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        send(.wodInfoSheetDismissed)
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
    
    private var exerciseList: some View {
        List {
            ForEach(store.exercises) { exercise in
                if let info = exercise.info, !info.isEmpty {
                    DisclosureGroup {
                        Text(info)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } label: {
                        HStack {
                            if let target = exercise.target {
                                target.displayText
                            }
                            
                            Text(exercise.type.displayName)
                                .foregroundStyle(.secondary)
                            
                            Spacer()
                            
                            if let weight = exercise.weight {
                                VStack(alignment: .trailing, spacing: 2) {
                                    if let men = weight.men {
                                        HStack(spacing: 2) {
                                            Group {
                                                Text("♂")
                                                Text("\(men)")
                                                    .foregroundStyle(.secondary)
                                            }
                                            .font(.caption)
                                        }
                                            
                                    }
                                    if let women = weight.women {
                                        HStack(spacing: 2) {
                                            Group {
                                                Text("♀")
                                                Text("\(women)")
                                                    .foregroundStyle(.secondary)
                                            }
                                            .font(.caption)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.vertical, 2)
                } else {
                    HStack {
                        if let target = exercise.target {
                            target.displayText
                        }
                        
                        Text(exercise.type.displayName)
                            .foregroundStyle(.secondary)
                        
                        Spacer()
                        
                        if let weight = exercise.weight {
                            VStack(alignment: .trailing, spacing: 2) {
                                if let men = weight.men {
                                    HStack(spacing: 2) {
                                        Group {
                                            Text("♂")
                                            Text("\(men)")
                                                .foregroundStyle(.secondary)
                                        }
                                        .font(.caption)
                                    }
                                        
                                }
                                if let women = weight.women {
                                    HStack(spacing: 2) {
                                        Group {
                                            Text("♀")
                                            Text("\(women)")
                                                .foregroundStyle(.secondary)
                                        }
                                        .font(.caption)
                                    }
                                }
                            }
                            Spacer().frame(width: 16)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }
    
    private var saveButton: some View {
        Button {
            send(.saveButtonTapped)
        } label: {
            Text("save")
        }
    }
}

#Preview("start") {
    NavigationStack {
        WodCreatorView(
            store: Store(
                initialState: WodCreatorFeature.State(),
                reducer: { WodCreatorFeature() }
            )
        )
    }
}

#Preview("ex1") {
    NavigationStack {
        WodCreatorView(
            store: Store(
                initialState: {
                    var state = WodCreatorFeature.State()
                    state.exercises = [
                        ExerciseSession(
                            type: .deadlift,
                            target: .reps(4),
                            weight: WeightConfiguration(men: 70, women: 40),
                            info: "Classic strength work"
                        ),
                        ExerciseSession(
                            type: .hangPowerSnatch,
                            target: .reps(3),
                            weight: WeightConfiguration(men: 70, women: 40),
                            info: nil
                        ),
                        ExerciseSession(
                            type: .overheadSquat,
                            target: .reps(2),
                            weight: WeightConfiguration(men: 70, women: 40),
                            info: "Classic strength work"
                        )
                    ]
                    return state
                }(),
                reducer: { WodCreatorFeature() }
            )
        )
    }
}
