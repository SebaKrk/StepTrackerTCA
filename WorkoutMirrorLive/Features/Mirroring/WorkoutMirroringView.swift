//
//  WorkoutMirroringView.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 30/07/2025.
//

import ComposableArchitecture
import SwiftUI

@ViewAction(for: WorkoutMirroringFeature.self)
struct WorkoutMirroringView: View {
    
    // MARK: - Properties
    @Bindable var store: StoreOf<WorkoutMirroringFeature>
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ScrollView {
                activeWorkoutView
            }
            .background(backgroundGradient)
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("Workout Mirroring")
            .toolbar {
                toolbarButton
            }
            .toolbar {
                bottomToolbarButton
            }
            .toolbar(removing: .title)
            .ignoresSafeArea(edges: .bottom)
        }
    }
    
    // MARK: - SubView
    
    @ToolbarContentBuilder
    var bottomToolbarButton: some ToolbarContent {
        ToolbarItemGroup(placement: .bottomBar) {
            Button {
                // Akcja
            } label: {
                Image(systemName: "square.and.arrow.up")
            }
            Spacer()
            Button {
                // Akcja
            } label: {
                Image(systemName: "heart")
            }
            Button {
                // Akcja
            } label: {
                Image(systemName: "snowflake")
            }
            Spacer()
            Button {
                // Akcja
            } label: {
                Text("Add")
            }
        }
    }
    
    @ToolbarContentBuilder
    var toolbarButton: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button {
                send(.xMarkButtonTapped)
            } label: {
                Image(systemName: "xmark")
            }
        }
    }
    
    @ToolbarContentBuilder
    var toolbarButton2: some ToolbarContent {
        ToolbarSpacer(.flexible)
        ToolbarItem(placement: .topBarLeading) {
            Button {
                
            } label: {
                Image(systemName: "square.and.arrow.up")
            }
        }
        ToolbarSpacer(.fixed)
        
        ToolbarItemGroup {
            Button {
                
            } label: {
                Image(systemName: "heart")
            }
            Button {
                
            } label: {
                Image(systemName: "snowflake")
            }
        }
        ToolbarSpacer(.fixed)
        ToolbarItem {
            Button {
                
            } label: {
                Text("Add")
            }
        }
    }
    
    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [.blue, .gray, .red]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
    
    private var activeWorkoutView: some View {
        GlassEffectContainer {
            VStack {
                heartRateView
                Spacer().frame(height: 10)
                currentHeartRatePercentageView
                activeEnergyBurnedView
                Spacer().frame(height: 10)
                currentHeartRateZoneView
            }
            .frame(minHeight: 220)
            .padding([.leading, .trailing], 8)
        }
        .glassEffect(.clear.interactive(), in: .rect(cornerRadius: 12))
        .padding()
    }
    
    private var heartRateView: some View {
        HStack {
            Group {
                Image(systemName: "heart.fill")
                    .foregroundColor(.red)
                Text("\(174)")//formatted(.number.precision(.fractionLength(0))))
                Text("BPM")
            }
            .font(.system(.title3, design: .rounded).monospacedDigit())
            .foregroundColor(.primary)
            Spacer()
            
            Text("Anaerobic")
                .font(.title3.weight(.semibold))
                .foregroundColor(.red)//store.currentHeartRateZone.color)
        }
    }
    
    private var currentHeartRatePercentageView: some View {
        VStack(spacing: 5) {
            Text("\(91)%")
                .font(.system(size: 60))
            //                .id(store.currentHeartRatePercentage)
            //                .transition(.push(from: .bottom))
                .animation(.snappy(duration: 0.3), value: 70)
        }
    }
    
    private var activeEnergyBurnedView: some View {
        HStack {
            Image(systemName: "flame.fill")
                .foregroundColor(.pink)
                .font(.system(.title2, design: .rounded))
            Text("\(321)")
            //            Text(Measurement(value: store.workoutMetrics.activeEnergy, unit: .kilocalories).formatted(MetricFormatter.workoutEnergy))
                .font(.system(.title3, design: .rounded).monospacedDigit())
                .foregroundColor(.primary)
            Text("Active\nEnergy")
                .font(.system(.caption, design: .rounded).smallCaps())
        }
    }
    
    private var currentHeartRateZoneView: some View {
        HStack {
            Spacer()
            Text("Anaerobic")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
}


//        GroupBox {
//            VStack {
//                heartRateView
//                Spacer().frame(height: 25)
//                currentHeartRatePercentageView
//                Spacer().frame(height: 25)
//                activeEnergyBurnedView
//            }
//            Spacer().frame(height: 25)
//            currentHeartRateZoneView
//        }
//        .padding()

//        GlassEffectContainer(spacing: 30.0) {
//            HStack {
//                Image(systemName: "sun.max.fill")
//                    .padding()
//
//                Image(systemName: "moon.stars.fill")
//                    .padding()
//
//                Image(systemName: "cloud.rain.fill")
//                    .padding()
//            }
//        }
//        .glassEffect()
