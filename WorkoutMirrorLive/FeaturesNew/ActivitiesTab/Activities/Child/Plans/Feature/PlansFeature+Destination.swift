//
//  PlansFeature+Destination.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 01/02/2026.
//

import ComposableArchitecture
import Foundation

extension PlansFeature {
    
    @Reducer
    enum Destination {

        /// Add a new training plan.
        case addPlan(AddPlanFeature)

        /// Show details of an existing training plan.
        case planDetail(PlanDetailFeature)

        /// Run an active workout session for a plan.
        case session(SessionFeature)
    }
    
}
