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
            Spacer()
            timeLineView
            HStack(spacing: 30) {
                Spacer()
                lockButton
                workoutActionButtonsView
                expandButton
                Spacer()
            }
            Spacer()
            if store.isExpanded {
                Group {
                    if store.isLocked {
                        unlockSlider
                    } else {
                        endWorkoutButton
                    }
                }
                .padding(.horizontal,12)
                Spacer()
            }
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
        sessionControlButton(systemImage: "pause", frame: 100) {
            send(.pauseWorkoutButtonTaped(true))
        }
        .opacity(store.isLocked ? 0.7 : 1)
        .disabled(store.isLocked)
    }
    
    private var resumeWorkoutButton: some View {
        sessionControlButton(systemImage: "play", frame: 100) {
            send(.resumeWorkoutButtonTapped(false))
        }
        .opacity(store.isLocked ? 0.7 : 1)
        .disabled(store.isLocked)
    }
    
    private var expandButton: some View {
        sessionControlButton(systemImage: store.isExpanded ? "chevron.down" : "chevron.up", frame: 50) {
            send(.expandButtonTapped)
        }
//        .opacity(store.isLocked ? 0.7 : 1)
//        .disabled(store.isLocked)
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


import SwiftUI

struct SlideAction: View {
    let title: String
    let systemImage: String
    let threshold: CGFloat    // 0.0...1.0, np. 0.8
    let onTriggered: () -> Void

    @State private var dragX: CGFloat = 0
    @State private var width: CGFloat = 0
    @State private var triggered = false

    var body: some View {
        GeometryReader { geo in
            let trackWidth = geo.size.width
            ZStack(alignment: .leading) {
                // Track
                Capsule()
                    .fill(.regularMaterial)
                    .overlay(
                        Capsule()
                            .strokeBorder(.white.opacity(0.12))
                    )

                // Progress fill
                Capsule()
                    .fill(.white.opacity(0.12))
                    .frame(width: max(56, dragX + 56))

                // Label centered
                HStack(spacing: 8) {
                    Image(systemName: systemImage)
                        .imageScale(.large)
                    Text(title)
                        .font(.system(.headline, design: .rounded))
                }
                .frame(maxWidth: .infinity)
                .foregroundStyle(.primary)
                .opacity(triggered ? 0 : 1)

                // Thumb
                Circle()
                    .fill(.thinMaterial)
                    .overlay(
                        Circle().strokeBorder(.white.opacity(0.25))
                    )
                    .shadow(radius: 3, y: 1)
                    .frame(width: 56, height: 56)
                    .overlay(
                        Image(systemName: "chevron.right")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(.primary)
                    )
                    .offset(x: dragX)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                guard !triggered else { return }
                                let x = max(0, min(value.translation.width, trackWidth - 56))
                                dragX = x
                                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                            }
                            .onEnded { _ in
                                guard !triggered else { return }
                                let goal = (trackWidth - 56) * threshold
                                if dragX >= goal {
                                    triggered = true
                                    let gen = UINotificationFeedbackGenerator()
                                    gen.notificationOccurred(.success)
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                                        dragX = trackWidth - 56
                                    }
                                    // opóźnienie, by pozwolić animacji dojechać
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                        onTriggered()
                                        reset(after: 0.5)
                                    }
                                } else {
                                    withAnimation(.spring) { dragX = 0 }
                                }
                            }
                    )
                    .accessibilityLabel(Text(title))
                    .accessibilityAddTraits(.isButton)
            }
            .onAppear { width = trackWidth }
        }
        .frame(height: 64)
        .contentShape(Rectangle())
    }

    private func reset(after delay: CGFloat) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            withAnimation(.spring) {
                dragX = 0
                triggered = false
            }
        }
    }
}

