//
//  HKWorkoutSessionState+Extension.swift
//  HealthHub
//
//  Created by Sebastian Sciuba on 22/06/2025.
//

import Foundation
import HealthKit

extension HKWorkoutSessionState {
    public var isActive: Bool {
        self != .notStarted && self != .ended
    }
}
