//
//  StopwatchView.swift
//  WorkoutMirrorLive
//

import ComposableArchitecture
import Commons
import SwiftUI

private let stopwatchFormatter = ElapsedTimeFormatter()

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
        .styledGroupBox()
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
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
        Text(stopwatchFormatter.string(for: store.time) ?? "00:00,00")
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
            Text(startStopLabel)
                .font(.body)
                .fontWeight(.medium)
                .frame(minWidth: 80)
        }
        .buttonStyle(.borderedProminent)
        .tint(.orange)
    }

    private var startStopLabel: String {
        if store.isRunning { return String(localized: "Stop", bundle: .main) }
        if store.time > 0  { return String(localized: "Continue", bundle: .main) }
        return String(localized: "Start", bundle: .main)
    }

}
