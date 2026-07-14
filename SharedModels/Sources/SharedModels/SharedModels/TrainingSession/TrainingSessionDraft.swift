//
//  TrainingSessionDraft.swift
//  SharedModels
//
//  Created by Sebastian Sciuba on 21/02/2026.
//

import Foundation

public struct TrainingSessionDraft: Equatable, Sendable {

    public var title: String
    public var date: Date
    public var activity: WorkoutActivityType
    public var location: WorkoutLocationType
    public var warmUp: WarmUpSession?
    public var workouts: [WorkoutSessionNew]
    public var coolDown: CoolDownSession?

    public init(
        title: String = "",
        date: Date = .now,
        activity: WorkoutActivityType = .crossTraining,
        location: WorkoutLocationType = .indoor,
        warmUp: WarmUpSession? = nil,
        workouts: [WorkoutSessionNew] = [],
        coolDown: CoolDownSession? = nil
    ) {
        self.title = title
        self.date = date
        self.activity = activity
        self.location = location
        self.warmUp = warmUp
        self.workouts = workouts
        self.coolDown = coolDown
    }

    public init(session: TrainingSession) {
        self.title = session.title
        self.date = session.date
        self.activity = session.activity
        self.location = session.location
        self.warmUp = session.warmUp
        self.workouts = session.workouts
        self.coolDown = session.coolDown
    }
}
