//
//  HRMirrorView.swift
//  WorkoutMirror Watch App
//
//  Created by Sebastian Sciuba on 25/03/2026.
//

import ComposableArchitecture
import SharedModels
import SwiftUI
import WatchKit

/// Displays live heart rate data mirrored from the paired iPhone workout session.
///
/// Shows:
/// - Current BPM in the zone color
/// - Zone label
/// - Elapsed workout time
@ViewAction(for: HRMirrorFeature.self)
struct HRMirrorView: View {

    // MARK: - Properties

    @Bindable var store: StoreOf<HRMirrorFeature>

    // MARK: - View

    var body: some View {
        TabView {
            hrTab
            controlsTab
            NowPlayingView()
        }
        .tabViewStyle(.page(indexDisplayMode: store.showTabIndicator ? .automatic : .never))
        .onTapGesture {
            send(.screenTapped)
        }
        .onAppear {
            send(.onAppear)
        }
        .toolbar(.hidden)
    }

    private var controlsTab: some View {
        return ZStack {
            Color.black.ignoresSafeArea()
            VStack {
                pauseResumeButton
                pauseResumeLabel
            }
        }
    }
    
    private var pauseResumeButton: some View {
        Button {
            send(.pauseResumeTapped)
        } label: {
            pauseResumeImage
        }
        .buttonStyle(.glass)
        .buttonBorderShape(.circle)
        .controlSize(.large)
    }
    
    private var pauseResumeImage: some View {
        Image(systemName: store.isPaused ? "play.fill" : "pause.fill")
            .font(.system(size: 26, weight: .semibold))
    }
    private var pauseResumeLabel: some View {
        Text(store.isPaused ? "Wznów" : "Pauza")
            .font(.caption.weight(.semibold))
    }

    private var hrTab: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()
                VStack(spacing: 4) {
                    Spacer()
                    heartRateView
                    zoneLabel
                    Spacer()
                    elapsedTimeView
                    Spacer()
                }
                .padding(.horizontal, 8)
            }
            .overlay {
                ZStack(alignment: .bottom) {
                    RoundedRectangle(
                        cornerRadius: geometry.size.width * 0.24,
                        style: .continuous
                    )
                    .inset(by: 1)
                    .strokeBorder(store.heartRateZone.color.opacity(0.6), lineWidth: 1)
                    .ignoresSafeArea()
                    .animation(.easeInOut(duration: 0.4), value: store.heartRateZone)

                    Capsule(style: .continuous)
                        .fill(Color.black)
                        .frame(width: 56, height: 18)
                        .offset(y: 4)
                        .ignoresSafeArea()
                }
            }
        }
    }

    // MARK: - Subviews

    private var heartRateView: some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Image(systemName: "heart.fill")
                .font(.title3)
                .foregroundStyle(store.heartRateZone.color)

            Text("\(store.heartRate)")
                .font(.system(size: 52, weight: .bold, design: .rounded))
                .foregroundStyle(store.heartRateZone.color)
                .monospacedDigit()

            Text("BPM")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .padding(.bottom, 8)
        }
    }

    private var zoneLabel: some View {
        Text(store.heartRateZone.title.uppercased())
            .font(.caption.weight(.semibold))
            .foregroundStyle(store.heartRateZone.color)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(store.heartRateZone.color.opacity(0.2), in: Capsule())
    }

    private var elapsedTimeView: some View {
        let total = store.elapsedSeconds
        let minutes = Int(total) / 60
        let seconds = Int(total) % 60
        let centiseconds = Int((total.truncatingRemainder(dividingBy: 1)) * 100)
        return Text(String(format: "%d:%02d.%02d", minutes, seconds, centiseconds))
            .font(.system(size: 28, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(.yellow)
    }

}

// MARK: - Preview

#Preview("Resting") {
    HRMirrorView(store: Store(initialState: {
        var state = HRMirrorFeature.State(elapsedSeconds: 185, maxHeartRate: 185)
        state.heartRate = 60
        state.heartRateZone = .resting
        return state
    }()) { HRMirrorFeature() })
}

#Preview("Recovery") {
    HRMirrorView(store: Store(initialState: {
        var state = HRMirrorFeature.State(elapsedSeconds: 623, maxHeartRate: 185)
        state.heartRate = 98
        state.heartRateZone = .recovery
        return state
    }()) { HRMirrorFeature() })
}

#Preview("Fat Burning") {
    HRMirrorView(store: Store(initialState: {
        var state = HRMirrorFeature.State(elapsedSeconds: 1240, maxHeartRate: 185)
        state.heartRate = 117
        state.heartRateZone = .fatBurning
        return state
    }()) { HRMirrorFeature() })
}

#Preview("Aerobic") {
    HRMirrorView(store: Store(initialState: {
        var state = HRMirrorFeature.State(elapsedSeconds: 2105, maxHeartRate: 185)
        state.heartRate = 138
        state.heartRateZone = .aerobic
        return state
    }()) { HRMirrorFeature() })
}

#Preview("Threshold") {
    HRMirrorView(store: Store(initialState: {
        var state = HRMirrorFeature.State(elapsedSeconds: 3421, maxHeartRate: 185)
        state.heartRate = 158
        state.heartRateZone = .threshold
        return state
    }()) { HRMirrorFeature() })
}

#Preview("Anaerobic") {
    HRMirrorView(store: Store(initialState: {
        var state = HRMirrorFeature.State(elapsedSeconds: 4812, maxHeartRate: 185)
        state.heartRate = 177
        state.heartRateZone = .anaerobic
        return state
    }()) { HRMirrorFeature() })
}
