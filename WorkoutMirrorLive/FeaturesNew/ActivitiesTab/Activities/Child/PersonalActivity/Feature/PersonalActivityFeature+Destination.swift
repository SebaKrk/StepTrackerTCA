//
//  PersonalActivityFeature+Destination.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 01/02/2026.
//

import ComposableArchitecture

extension PersonalActivityFeature {
    
    @Reducer
    enum Destination {
        
        /// Shows heart rate zone info sheet.
        case zoneInfo(HeartRateZoneInfoFeature)
        
        /// Shows activity details screen.
        case activityDetails(ActivityDetailsFeature)
    }
    
}
