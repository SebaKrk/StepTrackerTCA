//
// ControlsView.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 27/08/2025.
//

import ComposableArchitecture
import SwiftUI
import SharedModels
import HealthKit

@ViewAction(for: ControlsFeature.self)
struct ControlsView: View {
    
    // MARK: - Properties
    @Bindable var store: StoreOf<ControlsFeature>
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .center) {
            Spacer()
            if store.isLocked {
                Spacer()
                timeLineView
                unlockSlider
                    .padding(.horizontal,12)
                Spacer()
            } else {
                HStack {
                    workoutImage
                    timeLineView
                    workoutImage.hidden()
                }
                HStack(spacing: 30) {
                    Spacer()
                    lockButton
                    workoutActionButtonsView
                    expandButton
                    Spacer()
                }
            }
            if store.isExpanded && !store.isLocked {
                endWorkoutButton
                    .padding(.horizontal,12)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .frame(height: store.isExpanded ? 350 : 200)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .animation(.spring(), value: store.isExpanded)
    }
    
    private var timeLineView: some View {
        TimelineView(PeriodicTimelineSchedule(from: .now, by: 1.0 / 30.0)) { context in
            makeElapsedTimeView(context)
        }
    }
    
    private func makeElapsedTimeView(_ context: TimelineViewDefaultContext) -> some View {
        ElapsedTimeView(
            elapsedTime: store.elapsedTime,
            showSubseconds: true
        )
        //context.cadence == .live
        //        .frame(maxWidth: .infinity, alignment: .leading)
        .foregroundStyle(.yellow)
        .font(.system(.largeTitle, design: .rounded).monospacedDigit().lowercaseSmallCaps())
        .onChange(of: context.date) { _, newDate in
            send(.updateElapsedTime(newDate))
        }
    }
    
    @ViewBuilder
    private var workoutActionButtonsView: some View {
        mainControlButton
    }
    
    private var mainControlButton: some View {
        return sessionControlButton(
            systemImage: store.sessionState == .running ? "pause" : "play",
            frame: 85
        ) {
            send(.mainControlButtonTapped)
        }
        .disabledWithOpacity(store.isLocked, opacity: 0.7)
        .padding(.bottom, store.isExpanded ? 8 : 24)
    }
    
    private var expandButton: some View {
        sessionControlButton(systemImage: store.isExpanded ? "chevron.down" : "chevron.up", frame: 50) {
            send(.expandButtonTapped)
        }
        .disabledWithOpacity(store.isLocked, opacity: 0.7)
    }

    private var lockButton: some View {
        sessionControlButton(systemImage: store.isLocked ? "lock.fill" : "lock.open", frame: 50) {
            send(.lockButtonTapped)
        }
    }
    
    private var endWorkoutButton: some View {
        Button {
            send(.endWorkoutButtonTapped)
        } label: {
            Label("Koniec treningu", systemImage: "xmark")
                .bold()
                .frame(maxWidth: .infinity, minHeight: 50)
        }
        .buttonStyle(.borderedProminent)
        .foregroundStyle(.pink)
        .tint(.pink.opacity(0.2))
    }
    
    private var unlockSlider: some View {
        SlideAction(
            title: "Przesuń aby odblokować",
            systemImage: "lock.open",
            threshold: 0.75
        ) {
            send(.unlockConfirmed) // TCA lub dowolna akcja
        }
    }
    
    private var workoutImage: some View {
        Image(systemName: store.selectedWorkout?.iconCircleFill ?? "")
            .symbolRenderingMode(.hierarchical)
            .font(.system(size: 44, weight: .semibold))
            .foregroundStyle(.pink)
            .frame(width: 64, height: 64)
            .padding()
    }
    
    @ViewBuilder
    func sessionControlButton(systemImage: String, frame: CGFloat,
                              action: @escaping () -> Void) -> some View {
        Button {
            withAnimation {
                action()
            }
        } label:  {
            Image(systemName: systemImage)
                .frame(width: frame, height: frame)
                .font(.system(size: 30, weight: .medium))
                .background(
                    Circle()
                        .fill(.ultraThinMaterial)
                        .shadow(radius: 5)
                )
        }
        .buttonStyle(.plain)
    }
}

//.glassEffect(.regular.interactive(true), in: .buttonBorder)
//.shadow(radius: 6, y: 2)
//.accessibilityElement(children: .contain)

#Preview {
    ControlsView(
        store: Store(initialState: ControlsFeature.State(),
                     reducer: { ControlsFeature() })
    )
}
