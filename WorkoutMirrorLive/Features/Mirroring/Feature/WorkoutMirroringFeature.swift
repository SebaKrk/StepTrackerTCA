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
    
    @Dependency(\.workoutSessionClient) var client
    
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
                
            case let .workoutSessionState(value):
                state.workoutSessionState = value
                return .none
                
            case let .pauseChanged(value):
                state.isPaused = value
                if value {
                    state.pausedElapsedTime = state.elapsedTime
                }
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
                
            case .view(.hideToolBarButtonTapped):
                state.isToolbarHidden.toggle()
                return .none
                
            case .view(.heartRateZoneButtonTapped):
                state.destination = .heartRateZoneInfo(HeartRateZoneInfoFeature.State())
                return .none
                
            case let .view(.updateElapsedTime(date)):
                guard !state.isPaused else {
                    state.elapsedTime = state.pausedElapsedTime
                    return .none
                }
                state.elapsedTime = client.elapsedTimeAt(date)
                return .none
                
            
//
                // MARK: - Workout Actions
                
            case let .view(.pauseWorkoutButtonTaped(value)):
                return .run { send in
                    await send(.workoutSessionState(.paused))
                    await send(.pauseChanged(value))
                }
                
            case .view(.endWorkoutButtonTapped):
//                return .run { send in
//                    return .send(.workoutSessionState(.ended))
//                    await self.dismiss()
//                }
                print("endWorkoutButtonTapped")
                return .none
                
            case let .view(.resumeWorkoutButtonTapped(value)):
                
                return .run { send in
                    await send(.workoutSessionState(.running))
                    await send(.pauseChanged(value))
                }
                
            case .view(.xMarkButtonTapped):
                return .run { send in
                    await self.dismiss()
                }
                
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



