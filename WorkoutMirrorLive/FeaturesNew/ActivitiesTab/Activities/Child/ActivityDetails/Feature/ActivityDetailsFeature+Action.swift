//
//  ActivityDetailsFeature+Action.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 31/12/2025.
//

import ComposableArchitecture
import Foundation
import SharedModels

/// Implementation of `ActivityDetailsFeature` actions.
extension ActivityDetailsFeature {
    
    @CasePathable
    enum Action: ViewAction {
        
        case `internal`(Internal)
        
        /// Internal actions for state management and data loading.
        enum Internal {
            
            /// Heart rate zone distribution loaded successfully.
            case zoneDistributionLoaded([HeartRateZone: TimeInterval])
            
            /// All performance metrics loaded.
            /// - Parameters:
            ///   - mets: Metabolic Equivalent of Task
            ///   - trimp: Training Impulse score
            ///   - hrTSS: Heart Rate Training Stress Score
            ///   - hrRecovery: Heart rate recovery after 1 minute (bpm drop)
            ///   - intensityFactor: Workout effort relative to lactate threshold
            ///   - recoveryDemand: Estimated recovery time
            case metricsLoaded(mets: Double?, trimp: Double?, hrTSS: Double?, hrRecovery: Int?, intensityFactor: Double?, recoveryDemand: RecoveryDemand?)
            
            /// Toggles expansion state of heart rate zones section.
            case zoneExpand(Bool)
            
            /// Triggers loading of heart rate zone distribution.
            case loadZoneDistribution
            
            /// Triggers loading of all performance metrics.
            case loadMetrics
            
            
            
        }
        
        case view(View)
        
        /// View-triggered actions.
        enum View {
            
            /// Called when the view appears on screen.
            case viewDidAppear
            
            /// Called when user taps zone disclosure button.
            case zoneDiscusserButtonTapped(Bool)
        }
    }
}
