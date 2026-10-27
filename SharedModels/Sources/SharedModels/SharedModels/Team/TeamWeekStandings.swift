//
//  TeamWeekStandings.swift
//  SharedModels
//
//  Created by Sebastian Ściuba on 24/10/2026.
//

import Foundation

/// Week table: effort points and kcal summed over the week's entries.
public enum TeamWeekStandings {

    /// Rows sorted by points, then more workouts, then name.
    ///
    /// Every entry counts as a workout; only points from the current weights table are summed,
    /// since points from another table are not comparable.
    public static func rows(
        entriesByDay: [String: [TeamEntry]],
        myUid: String,
        weightsVersion: Int
    ) -> [TeamWeekRow] {
        var totalsByUid: [String: (name: String, points: Int, kcal: Double?, workouts: Int)] = [:]

        for entry in entriesByDay.values.joined() {
            var total = totalsByUid[entry.uid] ?? (entry.displayName, 0, nil, 0)
            if let points = entry.effortPoints, entry.weightsVersion == weightsVersion {
                total.points += points
            }
            if let kcal = entry.kcal {
                total.kcal = (total.kcal ?? 0) + kcal
            }
            total.workouts += 1
            totalsByUid[entry.uid] = total
        }

        let sorted = totalsByUid.sorted { lhs, rhs in
            if lhs.value.points != rhs.value.points { return lhs.value.points > rhs.value.points }
            if lhs.value.workouts != rhs.value.workouts { return lhs.value.workouts > rhs.value.workouts }
            return lhs.value.name < rhs.value.name
        }

        return sorted.enumerated().map { index, item in
            TeamWeekRow(
                uid: item.key,
                displayName: item.value.name,
                points: item.value.points,
                kcal: item.value.kcal.map { Int($0.rounded()) },
                workouts: item.value.workouts,
                place: index + 1,
                isMe: item.key == myUid
            )
        }
    }
}
