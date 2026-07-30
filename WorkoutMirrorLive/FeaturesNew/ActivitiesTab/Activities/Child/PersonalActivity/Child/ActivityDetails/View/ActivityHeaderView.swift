//
//  ActivityHeaderView.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 16/07/2026.
//

import HealthKit
import SharedModels
import SwiftUI

/// Header card of the details screen: activity type, duration, start/end times
/// and weekday. Pure presentation of `HKWorkout` — no reducer.
struct ActivityHeaderView: View {

    let workout: HKWorkout

    var body: some View {
        VStack {
            workoutActivityType
            workoutDates
        }
        .padding()
        .background(cardBackground)
    }

    // MARK: - Structure

    private var workoutActivityType: some View {
        HStack {
            activityTypeName
            durationText
            Spacer()
            activityTypeIcon
        }
    }

    private var workoutDates: some View {
        HStack {
            startTimeText
            Text("-")
            endTimeText
            Spacer()
            weekdayText
        }
        .font(.footnote)
        .foregroundStyle(.secondary)
    }

    // MARK: - Implementation

    private var activityTypeName: some View {
        Text(workout.workoutActivityType.name)
            .foregroundColor(.primary)
            .font(.title2)
            .bold()
    }

    private var durationText: some View {
        Text(formattedDuration)
            .foregroundColor(.gray)
            .font(.footnote)
    }

    private var activityTypeIcon: some View {
        Image(systemName: workout.workoutActivityType.iconNameSimple)
            .resizable()
            .scaledToFit()
            .foregroundColor(.primary)
            .frame(width: 25, height: 25)
    }

    private var startTimeText: some View {
        Text(workout.startDate,
             format: .dateTime.hour().minute().second())
    }

    private var endTimeText: some View {
        Text(workout.endDate,
             format: .dateTime.hour().minute().second())
    }

    private var weekdayText: some View {
        Text(workout.startDate, format: .dateTime.weekday(.wide))
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .stroke(.gray.opacity(0.5), lineWidth: 0.5)
            .fill(Color(.secondarySystemBackground).gradient.opacity(0.5))
    }

    private var formattedDuration: String {
        let minutes = Int(workout.duration) / 60
        return "\(minutes) min"
    }
}
