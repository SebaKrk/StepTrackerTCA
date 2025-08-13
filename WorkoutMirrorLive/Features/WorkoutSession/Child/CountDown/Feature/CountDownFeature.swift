//
//  CountDownFeature.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 05/08/2025.
//

import ComposableArchitecture
import Foundation
import SwiftUI

@Reducer
struct CountDownFeature {
    
    // MARK: - Dependencies
    
    @Dependency(\.countDownClient) var client
    @Dependency(\.continuousClock) var clock
    @Dependency(\.date) var date
    @Dependency(\.dismiss) var dismiss
    
    // MARK: - Reducer
    var body: some Reducer<State, Action> {
        Reduce<State, Action> { state, action in
            switch action {
                
            case .onAppear:
                return .send(.startCountDown)
                
            case .startCountDown:
                state.duration = state.duration
                state.timeRemaining = state.duration
                state.endDate = date().addingTimeInterval(state.duration)
                state.isActive = true
                
                return .run { send in
                    for await _ in await clock.timer(interval: .milliseconds(100)) {
                        await send(.timerTick)
                    }
                }
                //.cancellable(id: CancelID.timer)
                
            case .timerTick:
                guard let endDate = state.endDate else {
                    return .none
                }
                
                let remainingTime = endDate.timeIntervalSince(date())
                
                if remainingTime > 0 {
                    state.timeRemaining = remainingTime
                    return .none
                } else {
                    return .concatenate(
                        .send(.endCountDown),
                        .send(.timerFinished)
                    )
                }
                
            case .endCountDown:
                state.isActive = false
                state.timeRemaining = state.duration
                state.endDate = nil
                
                //return .cancel(id: CancelID.timer)
                return .none
                
            case .timerFinished:
                state.timerFinished = true
                return .send(.startWorkout)
                
            case .startWorkout:
                print("Starting workout...")
                return .run { send in
                    print("Closing view first...")
                    await send(.closeView)
                    
                    await client.startWorkout()
                    print("Workout started!")
                }
                
            case .closeView:
                /// obsluzone w rodzicu
                return .none
            }
        }
    }
}

extension CountDownFeature {
    
    // MARK: - Action
    
    enum Action {
        
        case startCountDown
        
        case endCountDown
        
        case timerTick
        
        case timerFinished
        
        case startWorkout
        
        case closeView
        
        case onAppear
    }
    
}

extension CountDownFeature {
    enum CancelID {
        case timer
    }
}


import HealthKit

extension CountDownFeature {
    
    @ObservableState
    struct State: Equatable {
        
        var timeRemaining: TimeInterval = 3
        
        var duration: TimeInterval = 3
        
        var isActive: Bool = false
        
        var endDate: Date?
        
        var timerFinished: Bool = false
        
        var trimValue: Double {
            timeRemaining > 0 ? timeRemaining / duration : 0
        }
        
        var isSettingTrim: Bool {
            timeRemaining == duration
        }
    }
    
}
