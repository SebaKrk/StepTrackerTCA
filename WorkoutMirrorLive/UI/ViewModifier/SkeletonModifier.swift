//
//  SkeletonModifier.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 18/10/2025.
//

import SwiftUI

struct SkeletonModifier: ViewModifier {
    let isLoading: Bool
    
    func body(content: Content) -> some View {
        content
            .redacted(reason: isLoading ? .placeholder : [])
            .shimmer(isActive: isLoading)
    }
}
