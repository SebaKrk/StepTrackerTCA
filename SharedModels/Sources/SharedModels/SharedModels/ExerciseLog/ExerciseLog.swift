//
//  ExerciseLog.swift
//  SharedModels
//
//  Created by Sebastian Sciuba on 24/04/2026.
//

import Foundation

/// A single exercise instance from a completed workout — one row per exercise per WOD.
public struct ExerciseLog: Identifiable, Equatable, Codable, Sendable {

    public var id: UUID
    public var date: Date

    // Exercise identity
    public var exerciseType: ExerciseType?
    public var unmatchedName: String?
    public var category: MovementCategory?

    // Training context
    public var workoutPlanScoreId: UUID?
    public var wodName: String?

    // Plan (pre-fill)
    public var plannedReps: String?
    public var plannedWeight: Double?

    // Actual
    public var actualWeight: Double?
    public var actualReps: String?
    public var scaling: ScalingType
    public var isPR: Bool

    // HR per phase
    public var avgHeartRate: Double?
    public var maxHeartRate: Double?
    public var phaseStartDate: Date?
    public var phaseEndDate: Date?
    public var timeInPhase: Double?

    // Computed at save time
    public var volumeLoad: Double?
    public var tempoPerRound: Double?

    public var note: String?
    public var editableUntil: Date?

    public init(
        id: UUID = UUID(),
        date: Date = Date(),
        exerciseType: ExerciseType? = nil,
        unmatchedName: String? = nil,
        category: MovementCategory? = nil,
        workoutPlanScoreId: UUID? = nil,
        wodName: String? = nil,
        plannedReps: String? = nil,
        plannedWeight: Double? = nil,
        actualWeight: Double? = nil,
        actualReps: String? = nil,
        scaling: ScalingType = .rx,
        isPR: Bool = false,
        avgHeartRate: Double? = nil,
        maxHeartRate: Double? = nil,
        phaseStartDate: Date? = nil,
        phaseEndDate: Date? = nil,
        timeInPhase: Double? = nil,
        volumeLoad: Double? = nil,
        tempoPerRound: Double? = nil,
        note: String? = nil,
        editableUntil: Date? = nil
    ) {
        self.id = id
        self.date = date
        self.exerciseType = exerciseType
        self.unmatchedName = unmatchedName
        self.category = category
        self.workoutPlanScoreId = workoutPlanScoreId
        self.wodName = wodName
        self.plannedReps = plannedReps
        self.plannedWeight = plannedWeight
        self.actualWeight = actualWeight
        self.actualReps = actualReps
        self.scaling = scaling
        self.isPR = isPR
        self.avgHeartRate = avgHeartRate
        self.maxHeartRate = maxHeartRate
        self.phaseStartDate = phaseStartDate
        self.phaseEndDate = phaseEndDate
        self.timeInPhase = timeInPhase
        self.volumeLoad = volumeLoad
        self.tempoPerRound = tempoPerRound
        self.note = note
        self.editableUntil = editableUntil
    }
}
