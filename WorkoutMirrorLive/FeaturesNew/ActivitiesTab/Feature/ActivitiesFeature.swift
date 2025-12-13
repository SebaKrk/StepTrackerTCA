//
//  ActivitiesFeature.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 20/08/2025.
//

import ComposableArchitecture
import Foundation
import HealthKit
import SharedModels

@Reducer
struct ActivitiesFeature {
        
    // MARK: - Dependency
    
    @Dependency(\.activityClient) var activityClient
    
    // MARK: - Reducer
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
                
                // MARK: - Action
                
            case let .selectedPickerChange(value):
                state.context = value
                return .none
                
                // MARK: - View Action
                
            case .view(.viewDidAppear):
                return .none
                
                // MARK: - Destination
                
            case .destination(_):
                return .none
            
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }
}

/// Implementation of `ActivitiesFeature` action
extension ActivitiesFeature {
    
    @CasePathable
    enum Action: ViewAction {
        
        // MARK: - Actions
        
        ///
        case selectedPickerChange(TrainingTabContext)
        
        // MARK: - View Actions
        
        case view(View)
        
        enum View {
                    
            /// Action triggered when the view appears on the screen.
            case viewDidAppear
            
            
        }
        
        // MARK: - Destination
        
        /// Action to handle navigation destinations within this feature.
        case destination(PresentationAction<Destination.Action>)
    }
}

/// Implementation of `ActivitiesFeature` state
extension ActivitiesFeature {
    
    @ObservableState
    struct State {
        
        // MARK: - Properties
        
        var viewState: ViewState = .success
        
        var context: TrainingTabContext = .personal
        
        var workouts: [HKWorkout] = []
        
        // MARK: - Destination
        
        /// destination from ActivitiesFeature
        @Presents var destination: Destination.State?
    }
    
}

/// Implementation of `ActivitiesFeature` destination
extension ActivitiesFeature {
    
    @Reducer
    enum Destination {
        
    }
}

//
//@Reducer
//struct ActivitiesFeature {
//    
//    // MARK: - Reducer
//    
//    var body: some Reducer<State, Action> {
//        Reduce { state, action in
//            switch action {
//                
//                // MARK: - Action
//                
//                // MARK: - View Action
//            case .view(.viewDidAppear):
//                return .none
//                
//            case .view(.settingsButtonTapped):
//                state.destination = .settings(SettingsFeature.State())
//                return .none
//                
//            case .view(.activitiesButtonTapped):
//                state.destination = .animationTest(AnimationFeature.State())
//                return .none
//                
//            case .destination(_):
//                return .none
//            }
//        }
//        .ifLet(\.$destination, action: \.destination)
//    }
//}
//
///// Implementation of `ActivitiesFeature` action
//extension ActivitiesFeature {
//    
//    @CasePathable
//    enum Action: ViewAction {
//        
//        // MARK: - Actions
//        
//        // MARK: - View Actions
//        
//        case view(View)
//        
//        enum View {
//                    
//            /// Action triggered when the view appears on the screen.
//            case viewDidAppear
//            
//            case settingsButtonTapped
//            
//            case activitiesButtonTapped
//            
//        }
//        
//        // MARK: - Destination
//        
//        /// Action to handle navigation destinations within this feature.
//        case destination(PresentationAction<Destination.Action>)
//    }
//}
//
///// Implementation of `ActivitiesFeature` state
//extension ActivitiesFeature {
//    
//    @ObservableState
//    struct State {
//        
//        // MARK: - Properties
//        
//        var badgeCount: Int = 5
//        
//        // MARK: - Destination
//        
//        /// destination from ActivitiesFeature
//        @Presents var destination: Destination.State?
//    }
//    
//}
//
///// Implementation of `ActivitiesFeature` destination
//extension ActivitiesFeature {
//    
//    @Reducer
//    enum Destination {
//        
//        /// Represents the destination for displaying in `SettingsFeature`.
//        case settings(SettingsFeature)
//        
//        /// Represents the destination for displaying in `AnimationFeature`.
//        case animationTest(AnimationFeature)
//    }
//}
