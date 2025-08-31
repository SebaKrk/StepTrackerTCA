//
//  ConfigurationFeature.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 23/08/2025.
//

import ComposableArchitecture
import SwiftUI
import SharedModels

@Reducer
struct ConfigurationFeature {
    
    // MARK: - Dependency
    
    @Dependency(\.dismiss) var dismiss
    @Dependency(\.continuousClock) var clock
    
    // MARK: - Reducer
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
                
                // MARK: - Core Action
            case let .core(.changeViewState(viewState)):
                state.viewState = viewState
                return .none
                
                // MARK: - View Action
            case .view(.viewDidAppear):
                return .none
                
            case .view(.closeButtonTapped):
                return .run { send in
                    await self.dismiss()
                }
                
            case .view(.backToDeviceButtonTapped):
                return .send(.core(.changeViewState(.device)))
                
            case .view(.backToActivityButtonTapped):
                return .send(.core(.changeViewState(.activity)))
                
            case .view(.startButtonTapped):
                if state.selectedDevice == .mirror {
                    // Tu bedzie odpalnie lusta po sprawdzeniu np czy na pewno mamy trawajaca sesje na zegarku
                    return .none
                } else {
                    guard let workout = state.selectedWorkout else {
                        print("Bład: Nie wybrano ćwiczenia")
                        return .none
                    }
                    return .run { send in
                        /// ta akacja jest przekazywana do AppTabNewFeature gdzie następnie wywoływany jest .fullScreenCover
                        await send(.delegate(.start(workout)))
                        await self.dismiss()
                    }
                }
                
                // MARK: - Child Action
            case .device(.select):
                switch state.selectedDevice {
                case .iphone, .watch:
                    return .run { send in
                        try await clock.sleep(for: .milliseconds(1250))
                        await send(.core(.changeViewState(.activity)), animation: .bouncy)
                    }
                case .mirror:
                    return .run { send in
                        try await clock.sleep(for: .milliseconds(1250))
                        await send(.core(.changeViewState(.ready)),
                                   animation: .bouncy)
                    }
                case .none:
                    return .none
                }
                    
            case let .device(.view(.buttonTapped(option))):
                state.selectedDevice = option
                return .none
                
            case let .activity(.select(value)):
                state.selectedWorkout = value
                return .run { send in
                    try await clock.sleep(for: .milliseconds(1250))
                    await send(.core(.changeViewState(.ready)),
                               animation: .bouncy)
                }
                
                // MARK: - Delegate Action
            case .delegate(_):
                return .none
                
                // MARK: - Childs Action
            case .device(_):
                return .none
                
            case .activity(_):
                return .none
                
            }
        }
        Scope(state: \.device, action: \.device) {
            DeviceFeature()
        }
        Scope(state: \.activity, action: \.activity) {
            ActivityPickerFeature()
        }
    }
}

extension ConfigurationFeature {
    
    enum CancelID: Hashable, Sendable {
        
        case advance
    }
}

/// Implementation of `ConfigurationFeature` action
extension ConfigurationFeature {
    
    @CasePathable
    enum Action: ViewAction {
        
        // MARK: - Core Actions
        
        case core(Internal)
        
        enum Internal {
            
            ///
            case changeViewState(SetupPhase)
            
        }
        
        // MARK: - View Actions
        
        case view(View)
        
        enum View {
            
            /// Action triggered when the view appears on the screen.
            case viewDidAppear
            
            ///
            case closeButtonTapped
            
            ///
            case backToDeviceButtonTapped
            
            ///
            case backToActivityButtonTapped
            
            ///
            case startButtonTapped
        }
        
        // MARK: - Delegate Actions
        
        case delegate(DelegateAction)
        
        enum DelegateAction: Equatable {
            
            ///
            case start(WorkoutType)
        }
        
        // MARK: - Child
        
        ///
        case device(DeviceFeature.Action)
        
        ///
        case activity(ActivityPickerFeature.Action)
    }
}

/// Implementation of `ConfigurationFeature` state
extension ConfigurationFeature {
    
    @ObservableState
    struct State {
        
        // MARK: - Properties
        
        ///
        var viewState: SetupPhase = .device
        
        ///
        var selectedDevice: DeviceOption? = nil
        
        ///
        var selectedWorkout: WorkoutType? = nil
        
        // MARK: - Child
        
        ///
        var device: DeviceFeature.State = .init()
        
        ///
        var activity: ActivityPickerFeature.State = .init()
    }
    
}
