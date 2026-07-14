//
//  WorkoutEntityProtocol.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 06/03/2025.
//

import CoreData
import Foundation

protocol WorkoutEntityProtocol: NSManagedObject {
    var id: String { get set }
    var date: Date { get set }
    var workoutType: String { get set }
    var movement: String { get set }
    var value: String { get set }
    var workouts: WorkoutsLogEntity? { get set }
}
