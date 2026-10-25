//
//  TrainingSession+TeamPlan.swift
//  SharedModels
//
//  Created by Sebastian Ściuba on 25/10/2026.
//

import Foundation

extension TrainingSession {

    /// Key that links a downloaded copy to a group's daily plan.
    public static func teamPlanId(groupId: String, day: String) -> String {
        "\(groupId)/\(day)"
    }

    /// Local copy of a group's plan: fresh ids everywhere (as on QR import) plus the team link.
    public func downloadedTeamCopy(id: UUID, date: Date, teamPlanId: String) -> TrainingSession {
        let copy = withNewIdentity(id: id, date: date)
        return TrainingSession(
            id: copy.id,
            date: copy.date,
            title: copy.title,
            activity: copy.activity,
            location: copy.location,
            warmUp: copy.warmUp,
            workouts: copy.workouts,
            coolDown: copy.coolDown,
            teamPlanId: teamPlanId
        )
    }
}
