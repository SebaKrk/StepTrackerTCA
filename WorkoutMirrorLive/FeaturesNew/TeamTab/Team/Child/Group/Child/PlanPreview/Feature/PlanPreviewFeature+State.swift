//
//  PlanPreviewFeature+State.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 25/10/2026.
//

import ComposableArchitecture
import Foundation
import SharedModels

extension PlanPreviewFeature {

    @ObservableState
    struct State: Equatable {

        // MARK: - Properties

        /// Group the plan belongs to.
        var groupId: String

        /// Today's plan of the group.
        var plan: TeamPlan

        /// A local copy is already in Plans.
        var isDownloaded: Bool

        /// Saving the copy is in flight.
        var isDownloading = false

        /// Message of the last failed download.
        var errorMessage: String?

        /// UI-only — warm-up card expanded.
        var isWarmupExpanded = true

        /// UI-only — cool-down card expanded.
        var isCooldownExpanded = true
    }

}
