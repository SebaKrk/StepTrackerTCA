//
//  PersonSettingsFeature+State.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 23/09/2025.
//

import ComposableArchitecture
import HealthHub
import SharedModels

/// Implementation of `PersonSettingsFeature` state
extension PersonSettingsFeature {
    
    @ObservableState
    struct State {
        
        // MARK: - Shared properties
        
//        @Shared(.appStorage("userSubscriptionTier"))
//        var subscriptionTier: SubscriptionTier = .basic
        
        @Shared(.appStorage(.subscriptionTier))
        var subscriptionTier: SubscriptionTier = .basic

        /// User'owy wybór formuły obliczania maxHR — persisted w UserDefaults pod kluczem
        /// "hrFormula". Czytane w PersonSettingsView żeby pokazać current value obok labelka
        /// "Formuła maxHR". Zmiana w `HRFormulaSettingsView` propaguje się natychmiast.
        @Shared(.appStorage("hrFormula"))
        var hrFormula: HRFormulaType = .tanaka
        
        // MARK: - Properties

        /// User profile loaded from local database (name, surname, nickname, email)
        var userProfile: UserProfile?

        /// User's age fetched from HealthKit
        var age: Int?

        /// User's biological sex fetched from HealthKit
        var sex: BiologicalSex?

        /// User's height fetched from HealthKit
        var height: HealthKitData?

        /// User's weight fetched from HealthKit
        var weight: HealthKitData?

        /// Resting heart rate fetched from HealthKit
        var restingHeartRate: HealthKitData?

        /// Max heart rate calculated from age and biological sex
        var maxHR: Int?
        
        // MARK: - Destination
        
        /// destination from PersonSettingsFeature
        @Presents var destination: Destination.State?
    }
    
}
