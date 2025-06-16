//
//  TrainingMetricView.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 28/05/2025.
//

import ComposableArchitecture
import Commons
import SwiftUI

@ViewAction(for: TrainingMetricFeature.self)
struct TrainingMetricView: View {
    
    // MARK: - Properties
    
    @Bindable var store: StoreOf<TrainingMetricFeature>
    
    // MARK: - View
    
    var body: some View {
        TimelineView(PeriodicTimelineSchedule(from: .now, by: 1.0 / 30.0)) { context in
            VStack(alignment: .leading) {
                Spacer()
                makeElapsedTimeView(context)
                heartRateMeasurement
                workoutEnergy
            }
            .ignoresSafeArea(edges: .bottom)
            .scenePadding()
        }
    }
    
    // MARK: - SubView
    
    private func makeElapsedTimeView(_ context: TimelineViewDefaultContext) -> some View {
        ElapsedTimeView(
            elapsedTime: store.elapsedTime,
            showSubseconds: context.cadence == .live
        )
        .frame(maxWidth: .infinity, alignment: .leading)
        .foregroundStyle(.yellow)
        .font(.system(.title, design: .rounded).monospacedDigit().lowercaseSmallCaps())
        .onAppear {
            send(.updateElapsedTime(context.date))
        }
        .onChange(of: context.date) { _, newDate in
            send(.updateElapsedTime(newDate))
        }
    }

    @ViewBuilder
    private var heartRateMeasurement: some View {
        if store.workoutMetrics.heartRate == 0 {
            VStack {
                Spacer().frame(height: 10)
                Text("Measuring...")
                    .font(.footnote)
                Spacer().frame(height: 10)
            }
        } else {
            heartRate
        }
    }
    
    private var heartRate: some View {
        HStack {
            heartImage
            Text(store.workoutMetrics.heartRate.formatted(MetricFormatter.heartRate))
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
        Text(Measurement(value: store.workoutMetrics.activeEnergy, unit: .kilocalories).formatted(MetricFormatter.workoutEnergy))
            .frame(maxWidth: .infinity, alignment: .leading)
            .font(.system(.title, design: .rounded).monospacedDigit().lowercaseSmallCaps())
    }
    
    private var heartImage: some View {
        Image(systemName: "heart.fill")
            .foregroundStyle(.red)
            .scaleEffect(store.animateHeart ? 1.4 : 1.0)
            .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: store.animateHeart)
    }
    
}
