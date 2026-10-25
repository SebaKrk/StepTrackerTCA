//
//  GroupFeature+Destination.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 25/10/2026.
//

import ComposableArchitecture
import Foundation

extension GroupFeature {

    @Reducer
    enum Destination {

        /// Sheet with the QR invite and who scanned it.
        case invite(InviteFeature)

        /// Sheet for publishing today's plan.
        case publishPlan(PublishPlanFeature)
    }

}
