//
//  CountDownFeature.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 05/08/2025.
//

import ComposableArchitecture
import Foundation
import SwiftUI

/// A feature responsible for managing the countdown timer before a workout session starts.
/// It visualizes the remaining time and triggers the workout start upon completion.
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
                
            // MARK: - Internal
                
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
                state.timeRemaining = 0
                state.endDate = nil
                return .none
                
            case .timerFinished:
                state.timerFinished = true
                return .send(.startWorkout)
                
            case .startWorkout:
                return .run { send in
                    await send(.closeView)
                    await client.startWorkout()
                }
                
                
            // MARK: - View Actions
                
            case .onAppear:
                return .send(.startCountDown)
                
            case .closeView:
                /// Handled by parent feature (SessionFeature) or dismiss dependency if needed.
                return .none
            }
        }
    }
}

extension CountDownFeature {
    
    // MARK: - Action
    
    enum Action {
        
        /// Triggered when the view appears. Stats the countdown sequence.
        case onAppear
        
        /// Internal action to initialize state and run the timer effect.
        case startCountDown
        
        /// Internal action to clean up state after countdown completes.
        case endCountDown
        
        /// Tick action triggered by the timer every 0.1s.
        case timerTick
        
        /// Triggered when the timer successfully reaches zero.
        case timerFinished
        
        /// Triggers the actual workout start via the client.
        case startWorkout
        
        /// Action to signal view dismissal (usually handled by parent).
        case closeView
    }
    
}

extension CountDownFeature {
    /// ID used for cancelling the timer effect (if needed).
    enum CancelID {
        case timer
    }
}


extension CountDownFeature {
    
    @ObservableState
    struct State: Equatable {
        
        /// Current time remaining in seconds.
        var timeRemaining: TimeInterval = 3
        
        /// Total duration of the countdown in seconds.
        var duration: TimeInterval = 3
        
        /// Indicates if the countdown is currently active.
        var isActive: Bool = false
        
        /// The calculated end date of the countdown.
        var endDate: Date?
        
        /// Flag indicating if the timer has finished.
        var timerFinished: Bool = false
        
        /// Calculated trim value for the circular progress view (0.0 to 1.0).
        var trimValue: Double {
            timeRemaining > 0 ? timeRemaining / duration : 0
        }
        
        /// Helper to determine if we are in the initial setup state.
        var isSettingTrim: Bool {
            timeRemaining == duration
        }
    }
    
}
