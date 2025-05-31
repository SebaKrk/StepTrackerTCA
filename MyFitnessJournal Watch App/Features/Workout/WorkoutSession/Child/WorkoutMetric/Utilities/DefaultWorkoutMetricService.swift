//
//  DefaultWorkoutMetricService.swift
//  MyFitnessJournal Watch App
//
//  Created by Sebastian Sciuba on 23/05/2025.
//

import Foundation
import Factory
import SwiftUI

final class DefaultWorkoutMetricService: WorkoutMetricService {
    
    // MARK: - Dependency
    
    @Injected(\.workoutManager) private var workoutManager
    
    // MARK: - API
    
    var workoutMetricsStream: AsyncStream<WorkoutMetrics> {
        workoutManager.workoutMetricsStream
    }
    
    
    //workoutManager.builder?.startDate
    
//    func elapsedTime(at context: TimelineViewDefaultContext) -> TimeInterval? {
//        workoutManager.builder?.elapsedTime(at: context.date)
//    }

}

//func timelineSchedule() -> MetricsTimelineSchedule {
//    MetricsTimelineSchedule(
//        from: workoutManager.builder?.startDate ?? Date(),
//        isPaused: workoutManager.session?.state == .paused
//    )
//}
//
//struct MetricsTimelineSchedule: TimelineSchedule {
//    var startDate: Date
//    var isPaused: Bool
//
//    init(from startDate: Date, isPaused: Bool) {
//        self.startDate = startDate
//        self.isPaused = isPaused
//    }
//
//    func entries(from startDate: Date, mode: TimelineScheduleMode) -> AnyIterator<Date> {
//        var baseSchedule = PeriodicTimelineSchedule(from: self.startDate,
//                                                    by: (mode == .lowFrequency ? 1.0 : 1.0 / 30.0))
//            .entries(from: startDate, mode: mode)
//        
//        return AnyIterator<Date> {
//            guard !isPaused else { return nil }
//            return baseSchedule.next()
//        }
//    }
//}
