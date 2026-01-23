//
//  TimerLiveActivity.swift
//  WorkoutSessionWidget
//
//  Created by Sebastian Sciuba on 20/01/2026.
//

import ActivityKit
import WidgetKit
import SwiftUI
import AppIntents
import SharedModels
import Foundation

struct TimerLiveActivity: Widget {
    
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TimerActivityAttributes.self) { context in
            timerLockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    timerDynamicIslandBottomView(context: context)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing) {
                        Text(context.attributes.timerName)
                        timerTimeView(context: context)
                    }
                }
            } compactLeading: {
                Image(systemName: "timer")
                    .foregroundColor(.orange)
            } compactTrailing: {
                HStack {
                    Spacer()
                    if context.state.isRunning {
                        Text(timerInterval: context.state.adjustedStartDate...Date.distantFuture, countsDown: false)
                            .foregroundStyle(.orange)
                            .monospacedDigit()
                    } else {
                        Text(getElapsedTime(from: context.state.adjustedStartDate, to: context.state.pauseDate ?? Date()))
                            .foregroundStyle(.orange)
                            .monospacedDigit()
                    }
                }
            } minimal: {
                Image(systemName: "timer")
                    .foregroundColor(.orange)
            }
        }
    }
    
    // MARK: - Lock Screen View
    
    @ViewBuilder
    func timerLockScreenView(
        context: ActivityViewContext<TimerActivityAttributes>
    ) -> some View {
        HStack {
            timerDynamicIslandBottomView(context: context)
            Spacer()
            timerTimeView(context: context)
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
    
    // MARK: - Time View (Text Only)
    
    @ViewBuilder
    func timerTimeView(
        context: ActivityViewContext<TimerActivityAttributes>
    ) -> some View {
        if context.state.isRunning {
            Text(timerInterval: context.state.adjustedStartDate...Date.distantFuture, countsDown: false)
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(.orange)
                .monospacedDigit()
                .multilineTextAlignment(.trailing)
        } else {
            Text(getElapsedTime(from: context.state.adjustedStartDate, to: context.state.pauseDate ?? Date()))
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(.orange)
                .monospacedDigit()
                .multilineTextAlignment(.trailing)
        }
    }
    
    // MARK: - Bottom View
    
    @ViewBuilder
    func timerDynamicIslandBottomView(
        context: ActivityViewContext<TimerActivityAttributes>,
    ) -> some View {
        HStack(spacing: 8) {
            Button(intent: PlayPauseTimerIntent(timerName: context.attributes.timerName)) {
                Image(systemName: context.state.isRunning ? "pause.fill" : "play.fill")
                    .foregroundStyle(.orange)
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            
            Button(intent: StopTimerIntent(timerName: context.attributes.timerName)) {
                Image(systemName: "stop.fill")
                    .foregroundStyle(.orange)
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
    }
    


    // MARK: - Helpers
    
    func formatTime(_ totalSeconds: TimeInterval) -> String {
        let hours = Int(totalSeconds) / 3600
        let minutes = Int(totalSeconds) / 60 % 60
        let seconds = Int(totalSeconds) % 60
        let centiseconds = Int((totalSeconds.truncatingRemainder(dividingBy: 1)) * 100)
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d,%02d", hours, minutes, seconds, centiseconds)
        } else {
            return String(format: "%02d:%02d,%02d", minutes, seconds, centiseconds)
        }
    }
    
    func getElapsedTime(from startDate: Date, to endDate: Date) -> String {
        let interval = endDate.timeIntervalSince(startDate)
        return formatTime(interval)
    }
}


