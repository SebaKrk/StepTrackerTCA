//
//  StyledGroupBoxModifier.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 21/10/2025.
//

import SwiftUI

/// ViewModifier dla stylizowanego GroupBox z przezroczystym tłem, obramowaniem i gradientem
struct StyledGroupBoxModifier: ViewModifier {

    /// Colours the whole card when the card itself carries a state; `nil` is the neutral skin.
    var tint: Color?

    func body(content: Content) -> some View {
        content
            .backgroundStyle(.clear)
            .foregroundStyle(.secondary)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(strokeColor, lineWidth: 0.5)
                    .fill(fillStyle)
            )
    }

    private var strokeColor: Color {
        tint?.opacity(0.45) ?? .gray.opacity(0.5)
    }

    private var fillStyle: AnyShapeStyle {
        guard let tint else {
            return AnyShapeStyle(Color(.secondarySystemBackground).gradient.opacity(0.5))
        }
        return AnyShapeStyle(tint.gradient.opacity(0.16))
    }
}
