//
//  TeamEntryBuilder.swift
//  SharedModels
//
//  Created by Sebastian Ściuba on 25/10/2026.
//

import Foundation

/// Builds the entry a finished workout posts to its group's daily plan.
public enum TeamEntryBuilder {

    /// Entry for the scored block; effort, coverage and the warm-start flag come from the window
    /// that starts at the workout start and lasts the plan length.
    public static func entry(
        uid: String,
        displayName: String,
        plan: TeamPlan,
        scoredResult: WodScoreResult?,
        scoredBlock: WorkoutSessionNew?,
        division: BoardDivision,
        hrBuffer: [(date: Date, bpm: Double)],
        maxHR: Double,
        windowStart: Date,
        kcal: Double?,
        existing: TeamEntry?,
        today: String,
        now: Date
    ) -> TeamEntry {
        let score = scoredResult.map {
            BoardScore($0, blockType: scoredBlock?.type ?? .forTime, timeCapMinutes: scoredBlock?.timeCap)
        } ?? .unranked
        let secondsByZone = TeamEffortWindow.secondsByZone(
            buffer: hrBuffer,
            maxHR: maxHR,
            start: windowStart,
            minutes: plan.sessionMinutes
        )
        let hasHeartRate = !secondsByZone.isEmpty
        return TeamEntry(
            uid: uid,
            displayName: displayName,
            score: score,
            division: division,
            effortPoints: hasHeartRate ? EffortPointsScoring.points(from: secondsByZone) : nil,
            weightsVersion: hasHeartRate ? EffortPointsScoring.currentWeightsVersion : nil,
            kcal: kcal,
            windowStart: windowStart,
            measuredMinutes: TeamEffortWindow.measuredMinutes(buffer: hrBuffer, start: windowStart, minutes: plan.sessionMinutes),
            hrVerified: hasHeartRate,
            startedAfterActivity: TeamEffortWindow.startedWarm(buffer: hrBuffer, maxHR: maxHR, start: windowStart),
            isLate: today != plan.id,
            submittedAt: existing?.submittedAt ?? now,
            editedAt: existing == nil ? nil : now
        )
    }
}
