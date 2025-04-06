//
//  Dependencies+ContainerExtension.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 28/12/2024.
//

import Factory
import Foundation

/// Container for application dependencies.
///
/// This extension provides a centralized place for registering and resolving
/// dependencies used across the application.
extension Container {
    
    /// A factory that provides a singleton instance of the `HealthKitManager`.
    ///
    /// - The factory is initialized with the default implementation, `DefaultHealthKitManager`.
    /// - This ensures that the same instance of `HealthKitManager` is used throughout the application.
    var healthKitManager: Factory<HealthKitManager> {
        Factory(self) { DefaultHealthKitManager() }.singleton
    }
    
    /// A factory that provides a shared instance of the `UserDefaultsService`.
    ///
    /// - This factory ensures that a shared instance of `UserDefaultsServiceManager` is
    ///   used to manage user preferences and settings stored in UserDefaults.
    var userDefaultsService: Factory<UserDefaultsService> {
        Factory(self) { UserDefaultsServiceManager() }.shared
    }
    
    /// A factory that provides a shared instance of the `SwiftDataManager`.
    ///
    /// - The factory is initialized with the default implementation, `DefaultSwiftDataManager`.
    /// - This ensures that the same instance of `SwiftDataManager` is used for handling
    ///   data persistence and operations related to SwiftData.
    //var swiftDataManager: Factory<SwiftDataManager> {
    //    Factory(self) { DefaultSwiftDataManger() }.shared
    //}
    
    /// A factory that provides a shared instance of the `RecordsRepository`.
    ///
    /// - The factory is initialized with the default implementation, `DefaultRecordsRepository`.
    /// - This ensures that the same instance of `RecordsRepository` is used for handling
    ///   data persistence and operations related to SwiftData.
    var recordsRepository: Factory<RecordsRepository> {
        Factory(self) { DefaultRecordsRepository() }.shared
    }
    
    /// A factory that provides a shared instance of the `GoalsRepository`.
    ///
    /// - The factory is initialized with the default implementation, `DefaultGoalsRepository`.
    /// - This ensures that the same instance of `GoalsRepository` is used for managing
    ///   goal-related data and operations throughout the application.
    var goalsRepository: Factory<GoalsRepository> {
        Factory(self) { DefaultGoalsRepository() }.shared
    }
    
    /// A factory that provides a shared instance of the `AddMeasurementRepository`.
    ///
    /// - The factory is initialized with the default implementation, `DefaultAddMeasurementRepository`.
    /// - This ensures that the same instance of `AddMeasurementRepository` is used for managing
    ///   the addition and persistence of new workout measurements.
    var addMeasurementRepository: Factory<AddMeasurementRepository> {
        Factory(self) { DefaultAddMeasurementRepository() }.shared
    }
    
    /// A factory that provides an instance of the `WeightLiftingRepository`.
    ///
    /// - The factory is initialized with the default implementation, `DefaultWeightLiftingRepository`.
    /// - Use this repository to handle operations related to weight lifting data.
    var weightLiftingRepository: Factory<WeightLiftingRepository> {
        Factory(self) { DefaultWeightLiftingRepository() }
    }
    
    /// A factory that provides an instance of the `WorkoutStrengthRepository`.
    ///
    /// - The factory is initialized with the default implementation, `DefaultWorkoutStrengthRepository`.
    /// - Use this repository to handle operations related to WorkoutStrength data.
    var workoutStrengthRepository: Factory<WorkoutStrengthRepository> {
        Factory(self) { DefaultWorkoutStrengthRepository() }
    }
    
    /// A factory that provides an instance of the `WorkoutStrengthRepository`.
    ///
    /// - The factory is initialized with the default implementation, `DefaultWorkoutFitnessRepository`.
    /// - Use this repository to handle operations related to WorkoutFitness data.
    var workoutFitnessRepository: Factory<WorkoutFitnessRepository> {
        Factory(self) { DefaultWorkoutFitnessRepository() }
    }
    
    /// A factory that provides an instance of the `WorkoutCrossRepository`.
    ///
    /// - The factory is initialized with the default implementation, `DefaultWorkoutCrossRepository`.
    /// - Use this repository to handle operations related to WorkoutCross data.
    var workoutCrossRepository: Factory<WorkoutCrossRepository> {
        Factory(self) { DefaultWorkoutCrossRepository() }
    }
    
    /// A factory that provides an instance of the `WorkoutHeroWodRepository`.
    ///
    /// - The factory is initialized with the default implementation, `DefaultWorkoutHeroWodRepository`.
    /// - Use this repository to handle operations related to WorkoutCross data.
    var workoutHeroWodRepository: Factory<WorkoutHeroWodRepository> {
        Factory(self) { DefaultWorkoutHeroWodRepository() }
    }
    
    /// A factory that provides a singleton instance of the `CoreDataManager`.
    ///
    /// - The factory is initialized with a new instance of `CoreDataManager`.
    /// - This ensures that the same instance of `CoreDataManager` is used for managing
    ///   Core Data operations throughout the application.
    var coreDataManger: Factory<CoreDataManager> {
        Factory(self) { CoreDataManager() }.singleton
    }
}
