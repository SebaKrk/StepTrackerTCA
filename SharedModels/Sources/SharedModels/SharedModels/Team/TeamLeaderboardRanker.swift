//
//  TeamLeaderboardRanker.swift
//  SharedModels
//
//  Created by Sebastian Ściuba on 24/10/2026.
//

import Foundation

/// Orders one day's entries into leaderboard rows.
public enum TeamLeaderboardRanker {

    /// Ranked entries first by place, then entries without a place.
    ///
    /// Scores of `blockId` rank within one division; effort points rank everyone together.
    public static func rows(
        entries: [TeamEntry],
        lens: TeamLeaderboardLens,
        blockId: UUID?,
        division: BoardDivision,
        myUid: String,
        weightsVersion: Int
    ) -> [TeamLeaderboardRow] {
        switch lens {
        case .score:
            return scoreRows(entries.filter { $0.division == division }, blockId: blockId, myUid: myUid)
        case .effort:
            return effortRows(entries, myUid: myUid, weightsVersion: weightsVersion)
        }
    }

    private static func scoreRows(_ entries: [TeamEntry], blockId: UUID?, myUid: String) -> [TeamLeaderboardRow] {
        let sorted = entries
            .map { entry in
                let score = blockId.map { entry.score(for: $0) } ?? .unranked
                return (entry: entry, score: score, key: BoardRankKey(score: score, submittedAt: entry.submittedAt))
            }
            .sorted { $0.key < $1.key }
        var place = 0
        return sorted.map { item in
            let isMe = item.entry.uid == myUid
            guard item.key.tier < BoardRankKey.unrankedTier else {
                return TeamLeaderboardRow(place: nil, entry: item.entry, score: item.score, isMe: isMe)
            }
            place += 1
            return TeamLeaderboardRow(place: place, entry: item.entry, score: item.score, isMe: isMe)
        }
    }

    // Points from another weights table are not comparable, so those entries get no place.
    private static func effortRows(_ entries: [TeamEntry], myUid: String, weightsVersion: Int) -> [TeamLeaderboardRow] {
        let comparable = entries
            .filter { $0.effortPoints != nil && $0.weightsVersion == weightsVersion }
            .sorted { lhs, rhs in
                let lhsPoints = lhs.effortPoints ?? 0
                let rhsPoints = rhs.effortPoints ?? 0
                return lhsPoints != rhsPoints ? lhsPoints > rhsPoints : lhs.submittedAt < rhs.submittedAt
            }
        let comparableIds = Set(comparable.map(\.uid))
        let others = entries
            .filter { !comparableIds.contains($0.uid) }
            .sorted { $0.displayName < $1.displayName }
        let ranked = comparable.enumerated().map { index, entry in
            TeamLeaderboardRow(place: index + 1, entry: entry, isMe: entry.uid == myUid)
        }
        let unranked = others.map { entry in
            TeamLeaderboardRow(place: nil, entry: entry, isMe: entry.uid == myUid)
        }
        return ranked + unranked
    }
}
