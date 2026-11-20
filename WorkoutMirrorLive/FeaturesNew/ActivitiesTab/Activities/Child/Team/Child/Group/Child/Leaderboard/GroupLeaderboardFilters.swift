//
//  GroupLeaderboardFilters.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 28/10/2026.
//

import ComposableArchitecture
import SharedModels
import SwiftUI

/// Leaderboard filters shown at the trailing end of the section title: ranking, division and period.
@ViewAction(for: GroupLeaderboardFeature.self)
struct GroupLeaderboardFilters: View {

    // MARK: - Properties

    @Bindable var store: StoreOf<GroupLeaderboardFeature>

    // MARK: - Body (structure)

    var body: some View {
        GlassEffectContainer(spacing: 8) {
            HStack(spacing: 8) {
                if store.range == .day {
                    rankingMenu
                    // Effort points rank everyone together, so the division matters only for a block's results.
                    if store.lens == .score {
                        divisionMenu
                    }
                }
                rangeMenu
            }
        }
        // Neutral labels — the screen's accent would colour every glass button.
        .tint(.primary)
    }

    // MARK: - Implementation

    // Choosing a block switches to its results, so points and blocks live in one menu.
    private var rankingMenu: some View {
        Menu {
            Picker(rankingTitle, selection: Binding(
                get: { store.rankingBlockId },
                set: { blockId in send(.rankingSelected(blockId)) }
            )) {
                Text(pointsTitle).tag(UUID?.none)
                if !store.scoredBlocks.isEmpty {
                    Divider()
                    ForEach(store.scoredBlocks) { block in
                        Text(blockTitle(block)).tag(Optional(block.id))
                    }
                }
            }
        } label: {
            menuLabel(rankedBlock?.name ?? pointsTitle)
        }
        .buttonStyle(.glass)
    }

    private var divisionMenu: some View {
        Menu {
            Picker(divisionTitle, selection: $store.division.sending(\.view.divisionChanged)) {
                Text(rxTitle).tag(BoardDivision.rx)
                Text(scaledTitle).tag(BoardDivision.scaled)
            }
        } label: {
            menuLabel(store.division == .rx ? rxTitle : scaledTitle)
        }
        .buttonStyle(.glass)
    }

    private var rangeMenu: some View {
        Menu {
            Picker(rangeTitle, selection: $store.range.sending(\.view.rangeChanged)) {
                ForEach(TeamLeaderboardRange.allCases) { range in
                    Text(range.title).tag(range)
                }
            }
        } label: {
            menuLabel(store.range.title)
        }
        .buttonStyle(.glass)
    }

    private func menuLabel(_ title: String) -> some View {
        Text(title)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.primary)
            .lineLimit(1)
    }

    private var rankedBlock: WorkoutSessionNew? {
        store.scoredBlocks.first { $0.id == store.rankingBlockId }
    }

    private func blockTitle(_ block: WorkoutSessionNew) -> String {
        let type = block.type.displayName
        return block.name == type ? type : "\(block.name) · \(type)"
    }

    // MARK: - Text

    private let rankingTitle = String(localized: "Ranking")
    private let pointsTitle = String(localized: "Points")
    private let divisionTitle = String(localized: "Division")
    private let rxTitle = String(localized: "Rx")
    private let scaledTitle = String(localized: "Scaled")
    private let rangeTitle = String(localized: "Period")
}
