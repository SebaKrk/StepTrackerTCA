//
//  LiveView.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 31/07/2025.
//

import ComposableArchitecture
import SwiftUI

@ViewAction(for: LiveFeature.self)
struct LiveView: View {
    
    // MARK: - Properties
    @Bindable var store: StoreOf<LiveFeature>
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            rootView
                .toolbar {
                    toolbarButton
                }
                .navigationDestination(
                    item: $store.scope(state: \.destination?.calendarView, action: \.destination.calendarView), destination: { store in
                        CalendarView(store: store)
                    }
                )
                .navigationDestination(
                    item: $store.scope(state: \.destination?.workoutDevicePickerView, action: \.destination.workoutDevicePickerView), destination: { store in
                        WorkoutDevicePickerView(store: store)
                    }
                )
            //                .navigationDestination(
            //                    item: $store.scope(state: \.destination?.workoutCreatorView, action: \.destination.workoutCreatorView), destination: { store in
            //                        WorkoutCreatorView(store: store)
            //                    }
            //                )
                .fullScreenCover(item: $store.scope(state: \.destination?.workoutCreatorView,
                                                    action: \.destination.workoutCreatorView)) { store in
                    WorkoutCreatorView(store: store)
                }
                                                    .fullScreenCover(item: $store.scope(state: \.destination?.workoutMirroringView,
                                                                                        action: \.destination.workoutMirroringView)) { store in
                                                        WorkoutMirroringView(store: store)
                                                    }
        }
    }
    
    // MARK: - SubView
    
    var rootView: some View {
        VStack {
            Spacer()
            HStack {
                calendarButton
                startWorkoutButton
                crateButton
            }
            deviceButton
            Spacer()
        }
    }
    
    @ToolbarContentBuilder
    private var toolbarButton: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                /// To bedzie sprawdzala wczesniej wszystki wyamagane zgody i ewentualnie przenosilo do zakladki person gdzie bedzie mozna kliknac odp zgode
                hrSensorButtonStatus
                bluetoothButtonStatus
                healthKitButtonStatus
                motionButtonStatus
            } label: {
                gearShapeImage
            }
        }
        
        ToolbarItem(placement: .topBarLeading) {
            Button {
                
            } label: {
                Image(systemName: "xmark")
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
            //            .buttonStyle(.borderedProminent)
            //            .foregroundStyle(.red, .pink)
            //            .tint(.white)
            //            .background(Circle().fill(Color.blue))
            //                .background(.blue, in: Circle())
        }
        
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                
            } label: {
                Image(systemName: "xmark")
            }
            .foregroundColor(.white)
            .background(Circle().fill(Color.blue))
            //                .background(.blue, in: Circle())
        }
        
    }
    
    // MARK: - ToolBar Buttons
    private var hrSensorButtonStatus: some View {
        Button {
            // akcja
        } label: {
            tabLabel("HR sensor", .authorized, "heart.fill")
        }
    }
    
    private var bluetoothButtonStatus: some View {
        Button {
            // akcja
        } label: {
            tabLabel("Bluetooth", .disabled, "antenna.radiowaves.left.and.right")
        }
    }
    
    private var healthKitButtonStatus: some View {
        Button {
            // akcja
        } label: {
            tabLabel("Health", .unauthorized, "waveform.path.ecg")
        }
    }
    
    private var motionButtonStatus: some View {
        Button {
            // akcja
        } label: {
            tabLabel("Motion", .unauthorized, "figure.walk")
        }
    }
    
    // MARK: - Main Buttons
    private var crateButton: some View {
        GlassButton("plus") {
            send(.navWorkoutCreatorButtonTapped)
        }
    }
    
    private var calendarButton: some View {
        GlassButton("calendar") {
            send(.navCalendarButtonTapped)
        }
    }
    
    private var startWorkoutButton: some View {
        GlassButton("play") {
            send(.startWorkoutMirrorButtonTapped)
        }
    }
    
    private var deviceButton: some View {
        GlassButton("applewatch.case.sizes") {
            send(.deviceButtonTapped)
        }
        //        Button {
        //            send(.deviceButtonTapped)
        //        } label: {
        //            Image(systemName: "applewatch.case.sizes")
        //                .padding()
        //        }
        //        .background(Circle().fill(Color.blue))
        //        .glassEffect(.regular.tint(.green))
        //        albo
        //        .buttonStyle(.glassProminent)
        //        .clipShape(.circle)
    }
    
    // MARK: - Helpers
    
    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [.white, .gray]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
    
    private func tabLabel(_ title: String, _ status: SensorStatus, _ icon: String) -> some View {
        Label {
            Text("\(title) \(status.emoji)")
        } icon: {
            Image(systemName: icon)
        }
    }
    
    private var gearShapeImage: some View {
        ZStack(alignment: .bottomTrailing) {
            Image(systemName: "gearshape")
                .imageScale(.large)
            Circle()
                .fill(Color.red)
                .frame(width: 10, height: 10)
                .overlay(
                    Text("!")
                        .font(.system(size: 7, weight: .bold))
                        .foregroundColor(.white)
                )
        }
    }
    
}

//            .sheet(item: $store.scope(state: \.destination?.openWorkoutMirroringView,
//                                      action: \.destination.openWorkoutMirroringView)) { store in
//                WorkoutMirroringView(store: store)
//
//                    .presentationDetents([.large])
//            }
