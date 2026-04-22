//
//  PhasePanelView.swift
//  WorkoutMirrorLive
//

import ComposableArchitecture
import SharedModels
import SwiftUI

@ViewAction(for: PhasePanelFeature.self)
struct PhasePanelView: View {

    // MARK: - Properties

    let store: StoreOf<PhasePanelFeature>

    // MARK: - Body

    var body: some View {
        GroupBox {
            panelContent
        } label: {
            panelLabel
        }
        .styledGroupBox()
        .onAppear { send(.appeared) }
    }

    // MARK: - Label

    private var panelLabel: some View {
        HStack {
            Label(
                String(localized: "Training Plan", bundle: .main),
                systemImage: "doc.text"
            )
            .font(.caption)
            .foregroundStyle(.secondary)

            Spacer()

            Text("\(store.currentIndex + 1) / \(store.phaseCount)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Content

    private var panelContent: some View {
        VStack(alignment: .leading) {
            Spacer().frame(height: 8)
            phaseHeader
            Spacer()
            phaseDescription
            Spacer()
            phaseNavigation
        }
    }

    private var phaseHeader: some View {
        HStack {
            Text(store.currentPhase.title)
                .font(.subheadline)
                .bold()
                .foregroundStyle(.primary)

            Spacer()
            timerButton
        }
    }

    @ViewBuilder
    private var phaseDescription: some View {
        let desc = store.currentPhase.snapshotDescription
        if !desc.isEmpty {
            Text(desc)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var phaseNavigation: some View {
        HStack {
            if store.canGoPrevious {
                Button {
                    send(.previousPhaseTapped)
                } label: {
                    Label(previousPhaseTitle, systemImage: "chevron.left")
                        .font(.caption)
                }
            }

            Spacer()

            if store.canGoNext {
                Button {
                    send(.nextPhaseTapped)
                } label: {
                    HStack(spacing: 4) {
                        Text(nextPhaseTitle)
                        Image(systemName: "chevron.right")
                    }
                    .font(.caption)
                }
            }
        }
    }

    private var timerButton: some View {
        Button { send(.timerTapped) } label: { timerView }
            .buttonStyle(.plain)
            .disabledWithOpacity(store.isTimerButtonDisabled)
    }

    private var timerView: some View {
        HStack(spacing: 4) {
            Image(systemName: store.isCountdown ? "timer" : "stopwatch")
                .font(.caption)
            Text(formattedTime)
                .font(.subheadline)
                .monospacedDigit()
                .foregroundStyle(.primary)
        }
        .foregroundStyle(.secondary)
    }

    // MARK: - Helpers

    private var formattedTime: String {
        let s = store.timerDisplay
        return String(format: "%d:%02d", s / 60, s % 60)
    }

    private var previousPhaseTitle: String {
        guard store.currentIndex > 0 else { return "" }
        return store.phases[store.currentIndex - 1].title
    }

    private var nextPhaseTitle: String {
        guard store.currentIndex < store.phaseCount - 1 else { return "" }
        return store.phases[store.currentIndex + 1].title
    }

}

// MARK: - Preview

#Preview("withPlan") {
    let session = TrainingSession.previewTrainingSession
    let store = Store(
        initialState: PhasePanelFeature.State(phases: session.phases)
    ) {
        PhasePanelFeature()
    }
    PhasePanelView(store: store)
        .padding()
}

#Preview("WOD only") {
    let phases: [WorkoutPhase] = [
        .wod(WorkoutSessionNew(
            name: "WOD 1",
            type: .forTime,
            timeCap: 12,
            rounds: 8,
            exercises: []
        ))
    ]
    let store = Store(
        initialState: PhasePanelFeature.State(phases: phases)
    ) {
        PhasePanelFeature()
    }
    PhasePanelView(store: store)
        .padding()
}
