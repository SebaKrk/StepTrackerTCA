//
//  TimerLiveActivity.swift
//  TimerActivityWidgetExtension
//
//  Created by Sebastian Sciuba on 20/01/2026.
//

import ActivityKit
import WidgetKit
import SwiftUI
import AppIntents
import SharedModels
import Foundation

struct TimerActivityWidgetExtensionLiveActivity: Widget {
    
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TimerActivityAttributes.self) { context in
            // Lock Screen view
            timerLockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded Dynamic Island Regions
                DynamicIslandExpandedRegion(.center) {
                    timerDynamicIslandCenterView(context: context, foregroundColor: .white)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    timerDynamicIslandBottomView(context: context, foregroundColor: .white)
                }
            } compactLeading: {
                Image(systemName: "timer")
                    .foregroundColor(.orange)
            } compactTrailing: {
                if context.state.isRunning {
                    Text(timerInterval: context.state.adjustedStartDate...Date.distantFuture, countsDown: false)
                        .foregroundStyle(.orange)
                        .monospacedDigit()
                        .frame(maxWidth: 40)
                } else {
                    Text(getElapsedTime(from: context.state.adjustedStartDate, to: context.state.pauseDate ?? Date()))
                        .foregroundStyle(.orange)
                        .monospacedDigit()
                        .frame(maxWidth: 40)
                }
            } minimal: {
                Image(systemName: "timer")
                    .foregroundColor(.orange)
            }
        }
    }
    
    // MARK: - Center View
    
    @ViewBuilder
    func timerDynamicIslandCenterView(
        context: ActivityViewContext<TimerActivityAttributes>,
        foregroundColor: Color
    ) -> some View {
        VStack {
            Text(context.attributes.timerName)
                .bold()
                .foregroundColor(foregroundColor)
            
            HStack {
                if context.state.isRunning {
                    Text(timerInterval: context.state.adjustedStartDate...Date.distantFuture, countsDown: false)
                        .font(.system(size: 44, weight: .semibold))
                        .foregroundStyle(.orange)
                        .multilineTextAlignment(.center)
                        .monospacedDigit()
                } else {
                    // When paused, show static time accumulated so far
                    Text(getElapsedTime(from: context.state.adjustedStartDate, to: context.state.pauseDate ?? Date()))
                        .font(.system(size: 44, weight: .semibold))
                        .foregroundStyle(.orange)
                        .multilineTextAlignment(.center)
                        .monospacedDigit()
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal)
        }
    }
    
    // MARK: - Bottom View
    
    @ViewBuilder
    func timerDynamicIslandBottomView(
        context: ActivityViewContext<TimerActivityAttributes>,
        foregroundColor: Color
    ) -> some View {
        HStack(spacing: 20) {
            // Play/Pause button
            Button(intent: PlayPauseTimerIntent(timerName: context.attributes.timerName)) {
                Image(systemName: context.state.isRunning ? "pause.fill" : "play.fill")
                    .bold()
                    .foregroundColor(foregroundColor)
            }
            
            // Stop button
            Button(intent: StopTimerIntent(timerName: context.attributes.timerName)) {
                Image(systemName: "stop.fill")
                    .bold()
                    .foregroundColor(foregroundColor)
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Lock Screen View
    
    @ViewBuilder
    func timerLockScreenView(
        context: ActivityViewContext<TimerActivityAttributes>
    ) -> some View {
        VStack {
            timerDynamicIslandCenterView(context: context, foregroundColor: .black)
            timerDynamicIslandBottomView(context: context, foregroundColor: .black)
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
    
    // MARK: - Helpers
    
    func formatTime(_ seconds: TimeInterval) -> String {
        let date = Date(timeIntervalSince1970: seconds)
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = seconds >= 3600 ? "HH:mm:ss" : "mm:ss"
        return formatter.string(from: date)
    }
    
    func getElapsedTime(from startDate: Date, to endDate: Date) -> String {
        let interval = endDate.timeIntervalSince(startDate)
        return formatTime(interval)
    }
}

// MARK: - INTENTS

public struct PlayPauseTimerIntent: LiveActivityIntent {
    public static var title: LocalizedStringResource = "Play/Pause Timer"
    
    @Parameter(title: "Timer Name")
    public var timerName: String?
    
    public init() {}
    
    public init(timerName: String) {
        self.timerName = timerName
    }
    
    public func perform() async throws -> some IntentResult {
        print("🔵 [INTENT] perform() called for timer: \(String(describing: timerName))")
        
        guard let timerName = timerName else {
            print("🔴 [INTENT] No timerName provided")
            return .result()
        }
        
        let activities = Activity<TimerActivityAttributes>.activities
        print("🔵 [INTENT] Found \(activities.count) active activities")
        
        guard let activity = activities.first(where: { $0.attributes.timerName == timerName }) else {
            print("🔴 [INTENT] Activity not found for name: \(timerName)")
            return .result()
        }
        
        print("🟢 [INTENT] Activity found! Current State isRunning: \(activity.content.state.isRunning)")
        
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
        print("🟢 [INTENT] Updated activity state to isRunning: \(newIsRunning)")
        
        return .result()
    }
}

@available(iOS 16.0, *)
public struct StopTimerIntent: LiveActivityIntent {
    public static var title: LocalizedStringResource = "Stop Timer"
    
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
