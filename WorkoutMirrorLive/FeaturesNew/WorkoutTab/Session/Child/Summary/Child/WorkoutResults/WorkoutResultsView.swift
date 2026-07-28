//
//  WorkoutResultsView.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 27/07/2026.
//

import ComposableArchitecture
import SwiftUI

/// Portable "Wyniki" section: header + one ResultCardView per WOD, each bound
/// to its own element store (canonical TCA collection scope) so a card
/// re-renders the moment its own fields change.
struct WorkoutResultsView: View {

    // MARK: - Properties

    let store: StoreOf<WorkoutResultsFeature>
    let accent: Color
    @Environment(\.summaryPalette) private var theme
    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader
            cards
        }
    }

    // MARK: - Structure

    private var sectionHeader: some View {
        VStack(alignment: .leading, spacing: 2) {
            resultsTitle
            if isEditable {
                resultsSubtitle
            }
        }
        .padding(.horizontal, 4)
    }

    private var cards: some View {
        ForEach(store.scope(state: \.cards, action: \.cards)) { cardStore in
            ResultCardView(store: cardStore, accent: accent)
        }
    }

    // MARK: - Implementation

    private var resultsTitle: some View {
        Text(String(localized: "Wyniki"))
            .font(.system(size: 20, weight: .heavy))
            .foregroundStyle(theme.ink)
    }

    private var resultsSubtitle: some View {
        Text(String(localized: "Uzupełnij wyniki, żeby trafiły do historii i analityki ćwiczeń."))
            .font(.system(size: 12.5))
            .foregroundStyle(theme.inkTertiary)
    }

    private var isEditable: Bool {
        !store.cards.allSatisfy(\.isReadOnly)
    }
}
