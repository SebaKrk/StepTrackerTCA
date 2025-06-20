//
//  CountDownFeature.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 20/06/2025.
//

import ComposableArchitecture
import Foundation
import SwiftUI

// MARK: - State
@Reducer
struct CountDownFeature {

    // MARK: - Dependencies
    
    @Dependency(\.continuousClock) var clock
    @Dependency(\.date) var date
    @Dependency(\.dismiss) var dismiss

    // MARK: - Reducer
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .send(.startCountDown)
                
            case .startCountDown:
                state.duration = state.duration
                state.timeRemaining = state.duration
                state.endDate = date().addingTimeInterval(state.duration)
                state.isActive = true
                
                return .run { send in
                    for await _ in clock.timer(interval: .milliseconds(100)) {
                        await send(.timerTick)
                    }
                }
                .cancellable(id: CancelID.timer)
                
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
                
                return .cancel(id: CancelID.timer)
                
            case .timerFinished:
                state.timerFinished = true
                // Tutaj możesz dodać logikę dla zakończenia timera
                // np. uruchomienie WorkoutManager
                return .run { send in
                    await self.dismiss()
                }
            }
        }
    }
}

