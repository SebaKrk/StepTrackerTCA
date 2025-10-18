//
//  ShimmerModifier.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 18/10/2025.
//

import SwiftUI

struct ShimmerModifier: ViewModifier {
    let isActive: Bool
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                Group {
                    if isActive {
                        GeometryReader { geometry in
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    .clear,
                                    .white.opacity(0.3),
                                    .clear
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            .frame(width: geometry.size.width * 2)
                            .offset(x: -geometry.size.width + (geometry.size.width * 2 * phase))
                        }
                        .mask(content)
                    }
                }
            )
            .onChange(of: isActive) { _, newValue in
                if newValue {
                    withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                        phase = 1
                    }
                } else {
                    phase = 0
                }
            }
            .onAppear {
                if isActive {
                    withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                        phase = 1
                    }
                }
            }
    }
}

