//
//  View+Shimmer.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 18/10/2025.
//

import SwiftUI

extension View {
    /// Applies shimmer animation effect
    ///
    /// - Parameter isActive: Whether the shimmer effect should be active
    /// - Returns: View with shimmer effect applied conditionally
    func shimmer(isActive: Bool = true) -> some View {
        modifier(ShimmerModifier(isActive: isActive))
    }
}
