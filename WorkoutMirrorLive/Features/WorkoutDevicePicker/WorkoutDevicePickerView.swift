//
//  WorkoutDevicePickerView.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 03/08/2025.
//

import ComposableArchitecture
import SwiftUI

@ViewAction(for: WorkoutDevicePickerFeature.self)
struct WorkoutDevicePickerView: View {
    
    // MARK: - Properties
    @Bindable var store: StoreOf<WorkoutDevicePickerFeature>
    
    // MARK: - Body
    
    var body: some View {
        rootView
            .navigationTitle("Device Picker")
            .fullScreenCover(item: $store.scope(state: \.destination?.workoutMirroringView,
                                                action: \.destination.workoutMirroringView)) { store in
                WorkoutMirroringView(store: store)
            }
    }
    
    // MARK: - SubView
    
    var rootView: some View {
        HStack {
            watchButton
            iPhoneButton
        }
    }
    
    private var watchButton: some View {
        GlassButton("applewatch") {
            send(.watchButtonTapped)
        }
    }
    
    private var iPhoneButton: some View {
        //GlassButton("iphone") {
        //send(.iPhoneButtonTapped)
        //}
        Group {
            Menu {
                Button {
                    send(.iPhoneButtonTapped)
                } label: {
                    if let workout = store.selectedWorkout {
                        Label {
                            Text("start workout")
                        } icon: {
                            Image(systemName: workout)
                        }
                    } else {
                        Text("Chose workout")
                    }
                    
                }
                
                Menu {
                    Button {
                        send(.selectedWorkoutButtonTapped("figure.cross.training"))
                    } label: {
                        Label {
                            Text("Cross training")
                        } icon: {
                            Image(systemName: "figure.cross.training")
                        }
                    }
                    
                    Button {
                        send(.selectedWorkoutButtonTapped("figure.boxing"))
                    } label: {
                        Label {
                            Text("Boxing training")
                        } icon: {
                            Image(systemName: "figure.boxing")
                        }
                    }
                    
                } label: {
                    Text("Select workout")
                        .tint(.primary)
                }
            } label: {
                GlassImage("iphone")
            }
        }
        .tint(.primary)
    }
    
}
