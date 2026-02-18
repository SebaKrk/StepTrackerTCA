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

        ///
        case addPlan(AddPlanFeature)

        ///
        case planDetail(PlanDetailFeature)
    }
    
}
