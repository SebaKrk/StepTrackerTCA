//
//  ScanPlanFeature.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 07/02/2026.
//

import ComposableArchitecture
import PhotosUI
import SwiftUI
import SharedModels

/// Feature responsible for extracting a workout plan from a photo.
///
/// Flow: Select photo → Load image data → Extract text → Edit extracted text.
/// The extraction strategy (on-device OCR+FM vs cloud Claude API) is determined
/// at runtime by ``WorkoutExtractionClient`` based on device capabilities.
@Reducer
struct ScanPlanFeature {

    // MARK: - Dependency
    
    @Dependency(\.workoutExtractionClient) var extractionClient

    // MARK: - Body

    var body: some Reducer<State, Action> {
        BindingReducer()

        Reduce { state, action in
            switch action {

            case .binding:
                return .none

                // MARK: - View Action

            case .view(.selectPhotoTapped):
                state.isPickerPresented = true
                return .none

            case let .view(.selectedPhotoChanged(item)):
                guard let item else { return .none }
                return .run { send in
                    if let data = try? await item.loadTransferable(type: Data.self) {
                        await send(.internal(.imageLoaded(data)))
                    } else {
                        await send(.internal(.imageLoaded(nil)))
                    }
                }

            case .view(.extractTextTapped):
                guard let imageData = state.selectedImageData else { return .none }
                state.viewState = .processingOCR
                return .run { send in
                    do {
                        let result = try await extractionClient.extractWorkout(imageData)
                        await send(.internal(.extractionCompleted(result)))
                    } catch {
                        await send(.internal(.extractionFailed(error.localizedDescription)))
                    }
                }

            case .view(.retryTapped):
                state.selectedImageData = nil
                state.extractedText = ""
                state.extractedWorkout = nil
                state.viewState = .idle
                return .none

            case .view(.clearImageTapped):
                state.selectedImageData = nil
                state.extractedText = ""
                state.extractedWorkout = nil
                state.viewState = .idle
                return .none

                // MARK: - Internal Action

            case let .internal(.imageLoaded(data)):
                guard let data else {
                    state.viewState = .failed(String(localized: "Could not load the selected image."))
                    return .none
                }
                state.selectedImageData = data
                state.viewState = .imageSelected
                return .none

            case let .internal(.extractionCompleted(workout)):
                state.extractedText = workout.rawText
                state.extractedWorkout = workout
                state.viewState = .textReady

                // MARK: - Detailed Workout Dump
                print("\n" + String(repeating: "=", count: 80))
                print("🏋️ EXTRACTED WORKOUT")
                print(String(repeating: "=", count: 80))
                print("📝 Name: \(workout.name)")
                print("📅 Date: \(workout.date)")
                print("⏱️  Total Duration: \(workout.totalEstimatedMinutes) min")
                print("📊 Sections Count: \(workout.sections.count)")
                print(String(repeating: "-", count: 80))

                for (index, section) in workout.sections.enumerated() {
                    print("\n🔹 Section \(index + 1): \(section.type.rawValue.uppercased())")
                    if let name = section.name {
                        print("   Name: \(name)")
                    }
                    if let duration = section.durationMinutes {
                        print("   Duration: \(duration) min")
                    }
                    if let timeCap = section.timeCapMinutes {
                        print("   Time Cap: \(timeCap) min")
                    }
                    if let rounds = section.rounds {
                        print("   Rounds: \(rounds)")
                    }
                    if let description = section.description {
                        print("   Description: \(description)")
                    }

                    if let exercises = section.exercises, !exercises.isEmpty {
                        print("   Exercises:")
                        for (exIndex, exercise) in exercises.enumerated() {
                            print("      \(exIndex + 1). \(exercise.name)", terminator: "")
                            if let reps = exercise.reps {
                                print(" - \(reps) reps", terminator: "")
                            }
                            print()

                            if let sets = exercise.sets {
                                for (index, set) in sets.enumerated() {
                                    print("         Scheme \(index + 1): \(set.setNumber) sets × \(set.reps) reps", terminator: "")
                                    if let intensity = set.intensity {
                                        print(" @ \(intensity)", terminator: "")
                                    }
                                    if let rest = set.restSeconds {
                                        print(" (rest: \(rest)s)", terminator: "")
                                    }
                                    print()
                                }
                            }

                            if let scaling = exercise.scalingOptions {
                                print("         Scaling: \(scaling)")
                            }
                        }
                    }

                    if let notes = section.notes {
                        print("   Notes: \(notes)")
                    }
                }

                print("\n" + String(repeating: "=", count: 80))
                print("✅ Extraction completed successfully")
                print(String(repeating: "=", count: 80) + "\n")

                // Test mapper
                let trainingSession = workout.toTrainingSession()
                print("\n🔄 TrainingSession dump:")
                dump(trainingSession)

                return .none

            case let .internal(.extractionFailed(error)):
                state.viewState = .failed(error)
                return .none
            }
        }
    }

}
