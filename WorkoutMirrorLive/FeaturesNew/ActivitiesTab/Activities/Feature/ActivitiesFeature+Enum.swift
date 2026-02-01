//
//  ActivitiesFeature+Enum.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 09/12/2025.
//

import Foundation

extension ActivitiesFeature {
    
    enum TrainingTabContext: CaseIterable, Identifiable, Equatable {
        
        case activity
        
        case plans
        
        var id: Self { self }
        
        var title: String {
            switch self {
            case .activity:
                return String(localized: "Activity", bundle: .main)
            case .plans:
                return String(localized: "Plans", bundle: .main)
            }
        }
    }
    
}
