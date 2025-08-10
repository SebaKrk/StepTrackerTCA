//
//  WorkoutMirroringFeature.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 31/07/2025.
//

import ComposableArchitecture
import Foundation

@Reducer
struct WorkoutMirroringFeature {
    
    // MARK: - Dependency
    
    @Dependency(\.dismiss) var dismiss
    
    // MARK: - Reducer
    
    var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce<State, Action> { state, action in
            switch action {
                // MARK: - Binding
            case .binding(_):
                return .none
                
                // MARK: - Action
            case let .bottomToolBarStateChanged(value):
                state.mirroringToolBarState = value
                return .none
                
                // MARK: - View Action
            case let .view(.bottomToolBarStateTapped(value)):
                return .send(.bottomToolBarStateChanged(value))
                
            case .view(.cameraButtonTapped):
                state.isActiveCamera.toggle()
                return .none
                
            case .view(.recordButtonTapped):
                state.recordIsActive.toggle()
                return .none
                
            case .view(.forwardMusicButtonTapped):
                print("forwardMusicButtonTapped")
                return .none
                
            case .view(.playPauseMusicButtonTapped):
                print("playPauseMusicButtonTapped")
                return .none
                
            case .view(.backwardMusicButtonTapped):
                print("backwardMusicButtonTapped")
                return .none
                
            case .view(.xMarkButtonTapped):
                return .run { send in
                    await self.dismiss()
                }
                
            case .view(.hideToolBarButtonTapped):
                state.isToolbarHidden.toggle()
                return .none
                
            case .view(.heartRateZoneButtonTapped):
                state.destination = .heartRateZoneInfo(HeartRateZoneInfoFeature.State())
                return .none
                
            case .view(.viewDidAppear):
                return .none
                
            case .destination(_):
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }
       
}

/// Implementation of `WorkoutMirroringFeature` action
extension WorkoutMirroringFeature {
    
    @CasePathable
    enum Action: ViewAction, BindableAction {
        
        // MARK: - Binding Action
        
        /// Handles changes in bindings for the state.
        case binding(BindingAction<State>)
        
        // MARK: - Action
        
        ///
        case bottomToolBarStateChanged(WorkoutMirroringToolBarState)
        
        // MARK: - View Actions
        
        case view(View)
        
        enum View {
            
            /// Action triggered when the view appears on the screen.
            case viewDidAppear
            
            ///
            case bottomToolBarStateTapped(WorkoutMirroringToolBarState)
            
            ///
            case heartRateZoneButtonTapped
            
            ///
            case hideToolBarButtonTapped
            
            // MARK: Camera
            ///
            case cameraButtonTapped
            
            ///
            case recordButtonTapped
            
            // MARK: Music
            
            ////
            case playPauseMusicButtonTapped
            
            ///
            case forwardMusicButtonTapped
            
            ///
            case backwardMusicButtonTapped
            
            // MARK: Workout
            
            ////
            case xMarkButtonTapped
        }
        
        // MARK: - Navigation and Presentation
        
        /// Action to handle navigation destinations within this feature.
        case destination(PresentationAction<Destination.Action>)
    }
}

/// Implementation of `WorkoutMirroringFeature` state
extension WorkoutMirroringFeature {
    
    @ObservableState
    struct State {
        
        // MARK: - Properties
        
        var elapsedTime: TimeInterval = 0
        
        ///
        var mirroringToolBarState: WorkoutMirroringToolBarState = .none
        
        ///
        var isActiveCamera: Bool = false
        
        ///
        var recordIsActive: Bool = false
        
        ///
        var isToolbarHidden: Bool = false
        
        // MARK: - Destination
        
        /// destination from WorkoutCreatorFeature
        @Presents var destination: Destination.State?
        
    }
    
}

/// Implementation of `WorkoutMirroringFeature` destination
extension WorkoutMirroringFeature {
    
    @Reducer
    enum Destination {
        
        /// Represents the destination for displaying in `HeartRateZoneInfoFeature`.
        case heartRateZoneInfo(HeartRateZoneInfoFeature)
        
    }
}
