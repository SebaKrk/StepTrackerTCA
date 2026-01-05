//
//  ActivitiesFeature+Enum.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 09/12/2025.
//

import Foundation

extension ActivitiesFeature {
    
    enum TrainingTabContext: CaseIterable, Identifiable, Equatable {
        
        case personal
        
        case team
        
        var id: Self { self }
        
        var title: String {
            switch self {
            case .personal:
                return String(localized: "Personal", bundle: .main)
            case .team:
                return String(localized: "Team", bundle: .main)
            }
        }
        
    }
}
