//
//  ElapsedTimeView.swift
//  WorkoutMirror Watch App
//

import SwiftUI

/// Displays elapsed workout time using `ElapsedTimeFormatter`.
///
/// Pass `showSubseconds: false` to switch to `MM:SS` format (always-on display).
/// Uses `TimelineView` cadence from the parent to drive the switch automatically.
struct ElapsedTimeView: View {

    let elapsedTime: TimeInterval
    let showSubseconds: Bool

    @State private var timeFormatter = ElapsedTimeFormatter()

    var body: some View {
        Text(NSNumber(value: elapsedTime), formatter: timeFormatter)
            .onAppear {
                timeFormatter.showSubseconds = showSubseconds
            }
            .onChange(of: showSubseconds) {
                timeFormatter.showSubseconds = showSubseconds
            }
    }
}
