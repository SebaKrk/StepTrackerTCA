//
//  StyledGroupBoxModifier.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 21/10/2025.
//

import SwiftUI

/// ViewModifier dla stylizowanego GroupBox z przezroczystym tłem, obramowaniem i gradientem
struct StyledGroupBoxModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .backgroundStyle(.clear)
            .foregroundStyle(.secondary)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(.gray.opacity(0.5), lineWidth: 0.5)
                    .fill(Color(.secondarySystemBackground).gradient.opacity(0.5))
            )
    }
}
