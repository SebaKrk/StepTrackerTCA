//
//  TeamLeaderboardRanker.swift
//  SharedModels
//
//  Created by Sebastian Ściuba on 24/10/2026.
//

import Foundation

/// Orders one day's entries into leaderboard rows.
public enum TeamLeaderboardRanker {

    /// Rows of one division: ranked entries first by place, then entries without a place.
    public static func rows(
        entries: [TeamEntry],
        lens: TeamLeaderboardLens,
        division: BoardDivision,
        myUid: String,
        weightsVersion: Int
    ) -> [TeamLeaderboardRow] {
        let inDivision = entries.filter { $0.division == division }
        switch lens {
        case .score:
            return scoreRows(inDivision, myUid: myUid)
        case .effort:
            return effortRows(inDivision, myUid: myUid, weightsVersion: weightsVersion)
        }
    }

    private static func scoreRows(_ entries: [TeamEntry], myUid: String) -> [TeamLeaderboardRow] {
        let sorted = entries
            .map { entry in (entry: entry, key: BoardRankKey(score: entry.score, submittedAt: entry.submittedAt)) }
            .sorted { $0.key < $1.key }
        var place = 0
        return sorted.map { item in
            guard item.key.tier < BoardRankKey.unrankedTier else {
                return TeamLeaderboardRow(place: nil, entry: item.entry, isMe: item.entry.uid == myUid)
            }
            place += 1
            return TeamLeaderboardRow(place: place, entry: item.entry, isMe: item.entry.uid == myUid)
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
