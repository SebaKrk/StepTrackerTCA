//
//  WorkoutMetricView.swift
//  MyFitnessJournal Watch App
//
//  Created by Sebastian Sciuba on 22/05/2025.
//

import ComposableArchitecture
import SwiftUI
import Factory

@ViewAction(for: WorkoutMetricFeature.self)
struct WorkoutMetricView: View {
    
    // MARK: - Properties
    
    @Bindable var store: StoreOf<WorkoutMetricFeature>
    
    // MARK: - View
    
    var body: some View {
        TimelineView(PeriodicTimelineSchedule(from: .now, by: 0.03)) { context in
            VStack(alignment: .leading) {
                Spacer()
                elapsedTime(context)
                heartRate
                workoutEnergy
            }
            .ignoresSafeArea(edges: .bottom)
            .scenePadding()
        }
      
    }
    
    /// workoutManager.builder?.elapsedTime(at: context.date) ?? 0
    private func elapsedTime(_ context: TimelineViewDefaultContext) -> some View {
        ElapsedTimeView(store: Store(
            initialState: ElapsedTimeFeature.State(
                elapsedTime: store.elapsedTime,
                showSubseconds: true),
            reducer: {
                ElapsedTimeFeature()
            }))
        .frame(maxWidth: .infinity, alignment: .leading)
        .foregroundStyle(.yellow)
        .font(.system(.title, design: .rounded).monospacedDigit().lowercaseSmallCaps())
    }

    private var heartRate: some View {
        HStack {
            heartImage
            Text(store.heartRate.formatted(MetricFormatter.heartRate))
                .font(.system(.title, design: .rounded).monospacedDigit().lowercaseSmallCaps())
            VStack {
                Spacer().frame(height: 10)
                Text("BMP")
                    .font(.footnote)
                    .baselineOffset(-2)
            }
            
        }
    }
    
    private var workoutEnergy: some View {
        Text(Measurement(value: store.activeEnergy, unit: .kilocalories).formatted(MetricFormatter.workoutEnergy))
            .frame(maxWidth: .infinity, alignment: .leading)
            .font(.system(.title, design: .rounded).monospacedDigit().lowercaseSmallCaps())
    }
    
    private var heartImage: some View {
        Image(systemName: "heart.fill")
            .foregroundStyle(.red)
            .scaleEffect(store.animateHeart ? 1.4 : 1.0)
            .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: store.animateHeart)
            .onAppear {
                send(.startHeartAnimation)
            }
    }
    
}

//#Preview {
//    WorkoutMetricView(store: Store(initialState: WorkoutMetricFeature.State(), reducer: {
//        WorkoutMetricFeature()
//    }))
//}

//        TimelineView(MetricsTimelineSchedule(from: workoutManager.builder?.startDate ?? Date(),
//                                             isPaused: workoutManager.session?.state == .paused)) { context in
            
//        }
//        by: (mode == .lowFrequency ? 1.0 : 1.0 / 30.0))
