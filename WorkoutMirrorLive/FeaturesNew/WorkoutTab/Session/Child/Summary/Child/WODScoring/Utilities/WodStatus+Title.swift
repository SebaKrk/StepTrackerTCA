//
//  WodStatus+Title.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 08/11/2026.
//

import Foundation

extension WODScoringFeature.WodStatus {

    /// Label on the card header's status control, frozen or selectable alike.
    var title: String {
        switch self {
        case .completed:
            String(localized: "Completed", bundle: .main)
        case .notFinished:
            String(localized: "Not finished", bundle: .main)
        }
    }
}
