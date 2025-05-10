//
//  WorkoutView.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 10/05/2025.
//

import ComposableArchitecture
import SwiftUI

@ViewAction(for: WorkoutFeature.self)
struct WorkoutView: View {
    
    // MARK: - Properties
    
    @Bindable var store: StoreOf<WorkoutFeature>
    
    @State private var photoSelection: PhotoSourceOption = .photo
    @State private var workoutSelection: WorkoutTypeOption = .customWorkout

    // MARK: - View
    
    var body: some View {
        NavigationStack {
            Group {
                VStack {
                    photoSourceOptionButton
                    workoutTypeOptionButton
                    historyOptionButton
                }
            }
            .navigationTitle("Workout")
            .navigationBarTitleDisplayMode(.inline)
        }
        
    }
    
    // MARK: - SubView
    
    private var photoSourceOptionButton: some View {
        PickerButtonView(selectedOption: $photoSelection) { option in
            switch option {
            case .library:
                print("chose libry")
            case .photo:
                print("chose photo")
            }
        }
        .padding()
    }
    
    private var workoutTypeOptionButton: some View {
        PickerButtonView(selectedOption: $workoutSelection) { option in
            switch option {
            case .customWorkout:
                print("chose custom workout")
            case .singleGoalWorkout:
                print("chose single workout")
            case .pacerWorkout:
                print("chose pacer workout")
            }
        }
        .padding()
    }
    
    private var historyOptionButton: some View {
        Group {
            Button {
                print("onHistoryTapped")
            } label: {
                Label("History", systemImage: "calendar")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.pink.opacity(0.1))
                    .foregroundColor(.pink)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(.pink, lineWidth: 0.5)
            )
        }
        .padding()
    }
    
}
