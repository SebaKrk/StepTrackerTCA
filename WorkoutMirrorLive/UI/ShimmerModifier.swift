//
//  ShimmerModifier.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 01/10/2025.
//


import SwiftUI

// MARK: - Skeleton Modifier

struct SkeletonModifier: ViewModifier {
    let isLoading: Bool
    
    func body(content: Content) -> some View {
        content
            .redacted(reason: isLoading ? .placeholder : [])
            .shimmer(isActive: isLoading)
    }
}

// MARK: - View Extension

extension View {
    /// Applies skeleton loading effect with shimmer animation
    ///
    /// - Parameter isLoading: Whether the skeleton effect should be active
    /// - Returns: View with skeleton effect applied conditionally
    ///
    /// # Example
    /// ```swift
    /// Text("Hello World")
    ///     .skeleton(isLoading: viewModel.isLoading)
    /// ```
    func skeleton(isLoading: Bool) -> some View {
        modifier(SkeletonModifier(isLoading: isLoading))
    }
}

// MARK: - Shimmer Modifier

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

extension View {
    /// Applies shimmer animation effect
    ///
    /// - Parameter isActive: Whether the shimmer effect should be active
    /// - Returns: View with shimmer effect applied conditionally
    func shimmer(isActive: Bool = true) -> some View {
        modifier(ShimmerModifier(isActive: isActive))
    }
}
