//
//  View+SkeletonModifier.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 01/10/2025.
//

import SwiftUI

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
