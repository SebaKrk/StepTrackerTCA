//
//  SlideAction.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 28/08/2025.
//

import SwiftUI

struct SlideAction: View {
    let title: String
    let systemImage: String
    let threshold: CGFloat
    let onTriggered: () -> Void

    @State private var dragX: CGFloat = 0
    @State private var width: CGFloat = 0
    @State private var triggered = false

    var body: some View {
        GeometryReader { geo in
            let trackWidth = geo.size.width
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(.regularMaterial)
                    .overlay(
                        Capsule()
                            .strokeBorder(.white.opacity(0.12))
                    )
                Capsule()
                    .fill(.white.opacity(0.12))
                    .frame(width: max(56, dragX + 56))
                HStack(spacing: 8) {
                    Image(systemName: systemImage)
                        .imageScale(.large)
                    Text(title)
                        .font(.system(.headline, design: .rounded))
                }
                .frame(maxWidth: .infinity)
                .foregroundStyle(.primary)
                .opacity(triggered ? 0 : 1)
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
