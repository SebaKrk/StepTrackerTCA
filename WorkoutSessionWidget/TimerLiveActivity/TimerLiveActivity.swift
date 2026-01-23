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
                        HStack(spacing: 4) {
                            Image(systemName: "heart.fill")
                                .foregroundStyle(.red)
                                .font(.system(size: 12))
                            Text("\(Int(context.state.heartRate))")
                                .font(.system(size: 16, weight: .bold))
                                .monospacedDigit()
                            Text("BPM")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                        timerTimeView(context: context)
                    }
                }
            } compactLeading: {
                HStack(spacing: 2) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(.red)
                    Text("\(Int(context.state.heartRate))")
                        .font(.system(size: 13, weight: .semibold))
                        .monospacedDigit()
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 4)
            } compactTrailing: {
                HStack(spacing: 2) {
                    Image(systemName: "timer")
                        .font(.system(size: 14))
                        .foregroundStyle(.orange)
                    timerTimeView(context: context, fontSize: 13)
                }
                .padding(.horizontal, 4)
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
        VStack {
            HStack {
                heartRateView(context)
                Spacer()
                heartRatePercentageView(context: context, fontSize: 32)
                Spacer()
                heartRateZoneView(context)
            }
            Divider().background(Color.orange)
            HStack {
                timerDynamicIslandBottomView(context: context)
                Spacer()
                timerTimeView(context: context)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
    
    // MARK: - Time View (Text Only)
    
    @ViewBuilder
    func timerTimeView(
        context: ActivityViewContext<TimerActivityAttributes>,
        fontSize: CGFloat = 24
    ) -> some View {
        if context.state.isRunning {
            Text(timerInterval: context.state.adjustedStartDate...Date.distantFuture, countsDown: false)
                .font(.system(size: fontSize, weight: .semibold))
                .foregroundStyle(.orange)
                .monospacedDigit()
                .multilineTextAlignment(.trailing)
        } else {
            Text(getElapsedTime(from: context.state.adjustedStartDate, to: context.state.pauseDate ?? Date()))
                .font(.system(size: fontSize, weight: .semibold))
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
    
    // MARK: SubView
    
    @ViewBuilder
    private func heartRateView(_ context: ActivityViewContext<TimerActivityAttributes>) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "heart.fill")
                .foregroundColor(.red)
                .font(.body)
                .symbolEffect(.pulse, options: .repeating)
            
            Text("\(Int(context.state.heartRate))")
                .font(.title3.bold())
                .foregroundStyle(.primary)
            
            Text("bpm")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
    
    @ViewBuilder
    private func heartRatePercentageView(context: ActivityViewContext<TimerActivityAttributes>, fontSize: CGFloat) -> some View {
        Text("\(context.state.heartRatePercentage)%")
            .font(.system(size: fontSize, weight: .regular, design: .monospaced))
            .foregroundStyle(.primary)
        
    }
    
    @ViewBuilder
    private func heartRateZoneView(_ context: ActivityViewContext<TimerActivityAttributes>) -> some View {
        Text(context.state.heartRateZone.rawValue.capitalized)
            .font(.body.weight(.semibold))
            .foregroundColor(context.state.heartRateZone.color)
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


