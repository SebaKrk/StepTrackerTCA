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
    
    @State var addExercise: Bool = false
    
    // MARK: - View
    
    var body: some View {
        VStack {
            Form {
                Section {
                    wodTitle
                    wodTimer
                    Text("Rounds")
                }
                Section {
                    Button {
                        addExercise = true
                    } label: {
                        HStack {
                            Text("add exerciseType")
                            Spacer()
                            Image(systemName: "plus")
                        }
                    }
                    if addExercise {
                        Text("ExerciseType")
                        Text("ExerciseTarget - reps")
                        Text("weight")
                        Text("Info")
                    }
                } header: {
                    Text("Exercises")
                }
            }
        }
        .sheet(isPresented: $store.isWodTitleSheetPresented) {
            wodTitleSheet
        }
    }
    
    private var wodTitle: some View {
        Button {
            send(.wodTitleSheetTapped)
        } label: {
            HStack {
                Text("Wod title")
                    .foregroundColor(.primary)
                Spacer()
                Text(store.wodTitle.isEmpty ? "Wod title" : store.wodTitle)
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
                TextField("Workout title", text: $store.wodTitle.sending(\.wodTitleChanged))
                    .multilineTextAlignment(.leading)
            }
            .navigationTitle("Workout Title")
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
    var wodTimer: some View {
        Button {
            send(.durationPickerTapped)
        } label: {
            HStack {
                Text("WOD timer picker")
                    .foregroundColor(.primary)
                Spacer()
                Text("\(store.selectedDuration) min")
                    .foregroundColor(.secondary)
                Image(systemName: store.isDurationPickerPresented ? "chevron.up" : "chevron.down")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
        }
        .buttonStyle(PlainButtonStyle())
        
        if store.isDurationPickerPresented {
            wodTimerPicker
        }
    }
    
    private var wodTimerPicker: some View {
        Picker("Czas trwania", selection: $store.selectedDuration.sending(\.durationChanged)) {
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

}


///import WorkoutKit
//CustomWorkout(
//    activity: HKWorkoutActivityType,
//    location: HKWorkoutSessionLocationType,
//    displayName: String?,
//    warmup: WorkoutStep?,
//    blocks: [IntervalBlock],
//    cooldown: WorkoutStep?
//)


//@available(iOS 26.0, *)
//@Generable
//struct WorkoutAI {
//    let name: String
//    let timeCap: Int?
//    let rounds: Int?
//    let exercises: [ExerciseAI]
//}
//
//// MARK: - Exercise Structure AI
//@available(iOS 26.0, *)
//@Generable
//struct ExerciseAI {
//    let type: ExerciseTypeAI
//    let target: ExerciseTargetAI?
//    let weight: WeightAI?
//    let info: String?
//}

//var timeSteper: some View {
//    VStack {
//        Text("Czas trwania: \(duration) min")
//            .font(.title2)
//            .padding()
//
//        Stepper("", value: $duration, in: 5...50, step: 5)
//            .labelsHidden()
//    }
//}
