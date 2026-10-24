//
//  TeamWeekStandings.swift
//  SharedModels
//
//  Created by Sebastian Ściuba on 24/10/2026.
//

import Foundation

/// Week table built from daily places, CrossFit Open style.
public enum TeamWeekStandings {

    /// Rows sorted by total places, then more workouts, then name.
    ///
    /// `entriesByDay` must contain a key for every day that had a plan (an empty array when nobody
    /// submitted); days without a key had no plan and do not count.
    public static func rows(
        entriesByDay: [String: [TeamEntry]],
        days: [String],
        lens: TeamLeaderboardLens,
        division: BoardDivision,
        myUid: String,
        weightsVersion: Int
    ) -> [TeamWeekRow] {
        let plannedDays = days.filter { entriesByDay[$0] != nil }
        var placesByUid: [String: [String: Int]] = [:]
        var namesByUid: [String: String] = [:]
        var rankedCountByDay: [String: Int] = [:]

        for day in plannedDays {
            let dayRows = TeamLeaderboardRanker.rows(
                entries: entriesByDay[day] ?? [],
                lens: lens,
                division: division,
                myUid: myUid,
                weightsVersion: weightsVersion
            )
            let ranked = dayRows.filter { $0.place != nil }
            rankedCountByDay[day] = ranked.count
            for row in ranked {
                placesByUid[row.entry.uid, default: [:]][day] = row.place
                namesByUid[row.entry.uid] = row.entry.displayName
            }
        }

        let totals = placesByUid.map { uid, places in
            let missingDays = plannedDays.filter { places[$0] == nil }
            let penalty = missingDays.reduce(0) { sum, day in sum + (rankedCountByDay[day] ?? 0) + 1 }
            return (
                uid: uid,
                name: namesByUid[uid] ?? "",
                places: places,
                missingDays: missingDays,
                total: places.values.reduce(0, +) + penalty,
                workouts: places.count
            )
        }
        .sorted { lhs, rhs in
            if lhs.total != rhs.total { return lhs.total < rhs.total }
            if lhs.workouts != rhs.workouts { return lhs.workouts > rhs.workouts }
            return lhs.name < rhs.name
        }

        return totals.enumerated().map { index, item in
            TeamWeekRow(
                uid: item.uid,
                displayName: item.name,
                placesByDay: item.places,
                missingDays: item.missingDays,
                total: item.total,
                workouts: item.workouts,
                place: index + 1,
                isMe: item.uid == myUid
            )
        }
    }
}
