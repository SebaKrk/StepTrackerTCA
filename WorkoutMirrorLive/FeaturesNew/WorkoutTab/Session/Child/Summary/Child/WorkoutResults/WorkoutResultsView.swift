//
//  WorkoutResultsView.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 27/07/2026.
//

import ComposableArchitecture
import SharedModels
import SwiftUI

/// Portable "Wyniki" section: header + one ResultCardView per WOD, each bound
/// to its own element store (canonical TCA collection scope) so a card
/// re-renders the moment its own fields change. Below the cards, PR-suggestion
/// rows offer adding a beaten record to the PR Board (editable embeds only).
@ViewAction(for: WorkoutResultsFeature.self)
struct WorkoutResultsView: View {

    // MARK: - Properties

    @Bindable var store: StoreOf<WorkoutResultsFeature>
    let accent: Color
    @Environment(\.summaryPalette) private var theme
    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader
            cards
            prSuggestionCards
        }
        .task { await send(.task).finish() }
        .sheet(
            item: $store.scope(state: \.prEditor, action: \.prEditor)
        ) { editorStore in
            PREntryEditorView(store: editorStore)
        }
    }

    // MARK: - Structure

    private var sectionHeader: some View {
        VStack(alignment: .leading, spacing: 2) {
            resultsTitle
            if store.isEditable {
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

    private var prSuggestionCards: some View {
        ForEach(store.prSuggestions) { suggestion in
            prSuggestionCard(suggestion)
        }
    }

    // MARK: - Implementation (header)

    private var resultsTitle: some View {
        Text(String(localized: "Results"))
            .font(.system(size: 20, weight: .heavy))
            .foregroundStyle(theme.ink)
    }

    private var resultsSubtitle: some View {
        Text(String(localized: "Fill in results so they land in history and exercise analytics."))
            .font(.system(size: 12.5))
            .foregroundStyle(theme.inkTertiary)
    }


    // MARK: - Implementation (PR suggestions)

    private func prSuggestionCard(_ suggestion: PRSuggestion) -> some View {
        Button {
            send(.prSuggestionTapped(suggestion))
        } label: {
            prSuggestionLabel(suggestion)
        }
        .buttonStyle(.plain)
    }

    private func prSuggestionLabel(_ suggestion: PRSuggestion) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                prSuggestionIcon
                VStack(alignment: .leading, spacing: 2) {
                    prSuggestionTitle
                    prSuggestionDetail(suggestion)
                }
                Spacer(minLength: 8)
                prSuggestionChevron
            }
        }
        .summaryCard()
    }

    private var prSuggestionIcon: some View {
        Image(systemName: "trophy.fill")
            .font(.body)
            .foregroundStyle(theme.mint)
            .frame(width: 36, height: 36)
            .background(theme.mintDim, in: .rect(cornerRadius: 12))
    }

    private var prSuggestionTitle: some View {
        Text(String(localized: "New record?"))
            .font(.system(size: 14, weight: .bold))
            .foregroundStyle(theme.ink)
    }

    private func prSuggestionDetail(_ suggestion: PRSuggestion) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(verbatim: "\(suggestion.movement.name) — \(weightLabel(suggestion.kilograms))")
                .font(.system(size: 12.5, weight: .semibold))
                .foregroundStyle(theme.inkSecondary)
            prSuggestionComparison(suggestion)
        }
    }

    @ViewBuilder
    private func prSuggestionComparison(_ suggestion: PRSuggestion) -> some View {
        if let previousBest = suggestion.previousBest {
            Text(String(localized: "previously \(weightLabel(previousBest))"))
                .font(.system(size: 11.5))
                .foregroundStyle(theme.inkTertiary)
        } else {
            Text(String(localized: "first result on the board"))
                .font(.system(size: 11.5))
                .foregroundStyle(theme.inkTertiary)
        }
    }

    private var prSuggestionChevron: some View {
        Image(systemName: "chevron.right")
            .font(.caption)
            .foregroundStyle(theme.inkTertiary)
    }

    private func weightLabel(_ kilograms: Double) -> String {
        PRScoreFormatter.string(for: .weight(kilograms: kilograms))
    }
}

// MARK: - Previews

#Preview("PR suggestion cards") {
    // prSuggestions is stored State, so the preview seeds it directly —
    // no cards, no database. The .task load no-ops (isEditable == false).
    var state = WorkoutResultsFeature.State()
    state.prSuggestions = [
        PRSuggestion(
            movement: PRCatalog.movement(id: "back-squat") ?? PRCatalog.movements[0],
            kilograms: 105,
            previousBest: 100
        ),
        PRSuggestion(
            movement: PRCatalog.movement(id: "strict-press") ?? PRCatalog.movements[0],
            kilograms: 62.5,
            previousBest: nil
        ),
    ]
    return ScrollView {
        WorkoutResultsView(
            store: Store(initialState: state) { WorkoutResultsFeature() },
            accent: SummaryTheme.mint
        )
        .padding(16)
    }
    .background(SummaryTheme.background)
}
