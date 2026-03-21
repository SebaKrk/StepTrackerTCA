//
//  PersonSettingsFeature+Action.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 23/09/2025.
//

import ComposableArchitecture
import SharedModels

/// Implementation of `PersonSettingsFeature` action
extension PersonSettingsFeature {
    
    @CasePathable
    enum Action: ViewAction {
        
        // MARK: - Actions

        /// Updates age from HealthKit
        case changeAge(Int?)

        /// Updates biological sex from HealthKit
        case changeSex(BiologicalSex?)

        /// Updates height from HealthKit
        case changeHeight(HealthKitData?)

        /// Updates weight from HealthKit
        case changeWeight(HealthKitData?)

        /// Updates resting heart rate from HealthKit
        case changeRestingHeartRate(HealthKitData?)

        /// Updates max heart rate calculated from age and sex
        case changeMaxHeartRate(Int?, BiologicalSex?)

        /// Triggers fetch of all HealthKit personal data
        case fetchPersonalData

        /// Triggers fetch of user profile from local database
        case fetchUserProfile

        /// Called when user profile fetch completes
        case profileLoaded(UserProfile?)

        // MARK: - View Actions

        case view(View)

        enum View {

            /// Action triggered when the view appears on the screen.
            case viewDidAppear

            /// Action triggered when close button is tapped
            case xMarkButtonTapped

            /// Action triggered when API key row is tapped
            case apiKeyTapped

            /// Action triggered when edit profile row is tapped
            case editProfileTapped
        }
        
        // MARK: - Destination
        
        /// Action to handle navigation destinations within this feature.
        case destination(PresentationAction<Destination.Action>)
    }
}
