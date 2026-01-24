//
//  WorkoutSessionWidgetBundle.swift
//  WorkoutSessionWidget
//
//  Created by Sebastian Sciuba on 15/01/2026.
//

import WidgetKit
import SwiftUI

@main
struct WorkoutSessionWidgetBundle: WidgetBundle {
    var body: some Widget {
        WorkoutSessionWidget()
        WorkoutSessionLiveActivity()
        TimerLiveActivity()
        TrainingReadinessWidget()
    }
}
