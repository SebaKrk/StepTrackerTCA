//
//  TimerActivityIntents.swift
//  SharedModels
//
//  Created by Sebastian Sciuba on 23/01/2026.
//

import ActivityKit
import AppIntents
import Foundation

public struct PlayPauseTimerIntent: LiveActivityIntent {
    public static let title: LocalizedStringResource = "Play/Pause Timer"
    
    @Parameter(title: "Timer Name")
    public var timerName: String?
    
    public init() {}
    
    public init(timerName: String) {
        self.timerName = timerName
    }
    
    public func perform() async throws -> some IntentResult {
        guard let timerName = timerName else {
            return .result()
        }
        
        let activities = Activity<TimerActivityAttributes>.activities
        
        guard let activity = activities.first(where: { $0.attributes.timerName == timerName }) else {
            return .result()
        }
        
        let currentState = activity.content.state
        
        let isPaused = !currentState.isRunning
        let newIsRunning = isPaused // If was paused, now running
        
        var newPauseDate: Date? = nil
        var newAdjustedStartDate = currentState.adjustedStartDate
        
        if newIsRunning {
            // Resuming: Calculate new adjusted start date
            // Start = Original Start + (Now - Pause Date)
            if let lastPauseDate = currentState.pauseDate {
                let pauseDuration = Date().timeIntervalSince(lastPauseDate)
                newAdjustedStartDate = currentState.adjustedStartDate.addingTimeInterval(pauseDuration)
            }
        } else {
            // Pausing: Set pause date
            newPauseDate = Date()
        }
        
        let updatedState = TimerActivityAttributes.ContentState(
            heartRate: currentState.heartRate,
            heartRateZone: currentState.heartRateZone,
            elapsedTime: currentState.elapsedTime,
            isRunning: newIsRunning,
            adjustedStartDate: newAdjustedStartDate,
            pauseDate: newPauseDate
        )
        
        await activity.update(ActivityContent(state: updatedState, staleDate: nil))
        
        return .result()
    }
}


public struct StopTimerIntent: LiveActivityIntent {
    public static let title: LocalizedStringResource = "Stop Timer"
    
    @Parameter(title: "Timer Name")
    public var timerName: String?
    
    public init() {}
    
    public init(timerName: String) {
        self.timerName = timerName
    }
    
    public func perform() async throws -> some IntentResult {
        guard let timerName = timerName else { return .result() }
        
        if let activity = Activity<TimerActivityAttributes>.activities.first(where: { $0.attributes.timerName == timerName }) {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
        
        return .result()
    }
}
