//
// ControlsView.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 27/08/2025.
//

import ComposableArchitecture
import SwiftUI

@ViewAction(for: ControlsFeature.self)
struct ControlsView: View {
    
    // MARK: - Properties
    @Bindable var store: StoreOf<ControlsFeature>
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .center) {
            timeLineView
                .padding()
            HStack(spacing: 16) {
                Spacer()
                sampleButton.hidden()
                workoutActionButtonsView
                expandButton
                Spacer()
            }
            Spacer().frame(height: 50)
            if store.isExpanded {
                endWorkoutButton
                    .padding()
                Spacer()
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: store.isExpanded ? 300 : 200)
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
        .font(.system(.title, design: .rounded).monospacedDigit().lowercaseSmallCaps())
        //        .onAppear {
        //            send(.updateElapsedTime(context.date))
        //        }
        //        .onChange(of: context.date) { _, newDate in
        //            send(.updateElapsedTime(newDate))
        //        }
    }
    
    @ViewBuilder
    private var workoutActionButtonsView: some View {
        switch store.sessionState {
        case .running:
            workoutPauseButton
        case .paused:
            resumeWorkoutButton
        }
    }
    
    private var workoutPauseButton: some View {
        sessionControlButton(systemImage: "pause", frame: 80) {
            send(.pauseWorkoutButtonTaped(true))
        }
    }
    
    private var resumeWorkoutButton: some View {
        sessionControlButton(systemImage: "play", frame: 80) {
            send(.resumeWorkoutButtonTapped(false))
        }
    }
    
    private var expandButton: some View {
        sessionControlButton(systemImage: store.isExpanded ? "chevron.down" : "chevron.up", frame: 50) {
            send(.expandButtonTapped)
        }
    }
    
    private var sampleButton: some View {
        sessionControlButton(systemImage: "1.lane", frame: 50) { }
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
    
    //    Button {
    //        withAnimation {
    //            workoutManager.endWorkout()
    //        }
    //    } label: {
    //        Image(systemName: "xmark")
    //            .frame(maxWidth: .infinity, minHeight: 50)
    //            .font(.largeTitle)
    //    }
    //    .padding(.leading)
    //    .buttonStyle(.borderedProminent)
    //    .tint(.red)
    
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

