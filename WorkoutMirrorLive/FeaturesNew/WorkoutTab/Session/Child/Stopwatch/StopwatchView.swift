//
//  StopwatchView.swift
//  WorkoutMirrorLive
//

import ComposableArchitecture
import SwiftUI

@ViewAction(for: StopwatchFeature.self)
struct StopwatchView: View {

    // MARK: - Properties

    let store: StoreOf<StopwatchFeature>

    // MARK: - Body

    var body: some View {
        GroupBox {
            VStack(spacing: 16) {
                if store.isManagingPhase {
                    backToPlanHeader
                }
                timeDisplay
                controls
            }
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        }
    }

    // MARK: - SubViews

    private var backToPlanHeader: some View {
        HStack {
            Button {
                send(.returnToPhaseTimerTapped)
            } label: {
                Label(
                    String(localized: "Back to plan", bundle: .main),
                    systemImage: "chevron.left"
                )
                .font(.caption)
            }
            Spacer()
        }
    }

    private var timeDisplay: some View {
        Text(formattedTime(store.time))
            .font(.system(size: 48, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(.orange)
    }

    private var controls: some View {
        HStack(spacing: 20) {
            if !store.isRunning && store.time > 0 {
                resetButton
            }
            startStopButton
        }
    }

    private var resetButton: some View {
        Button {
            send(.reset)
        } label: {
            Text("Reset")
                .font(.body)
        }
        .buttonStyle(.bordered)
        .tint(.orange)
    }

    private var startStopButton: some View {
        Button {
            send(store.isRunning ? .stop : .start)
        } label: {
            Text(store.isRunning ? "Stop" : "Start")
                .font(.body)
                .fontWeight(.medium)
                .frame(minWidth: 80)
        }
        .buttonStyle(.borderedProminent)
        .tint(.orange)
    }

    // MARK: - Helpers

    private func formattedTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        let centiseconds = Int((time.truncatingRemainder(dividingBy: 1)) * 100)
        return String(format: "%02d:%02d,%02d", minutes, seconds, centiseconds)
    }

}
