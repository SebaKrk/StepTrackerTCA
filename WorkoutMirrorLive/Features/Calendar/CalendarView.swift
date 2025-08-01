//
//  CalendarView.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 01/08/2025.
//

import ComposableArchitecture
import SwiftUI

@ViewAction(for: CalendarFeature.self)
struct CalendarView: View {
    
    // MARK: - Properties
    @Bindable var store: StoreOf<CalendarFeature>
    
    // MARK: - Body
    
    var body: some View {
        if !store.workoutCalendar.isEmpty {
            workoutCalendarList
                .navigationDestination(
                    item: $store.scope(
                        state: \.destination?.openWorkoutDetailsView,
                        action: \.destination.openWorkoutDetailsView),
                    destination: { store in
                        WorkoutDetailsView(store: store)
                    }
                )
        } else {
            contentUnavailable
        }
    }
    
    private var workoutCalendarList: some View {
        List(selection: $store.selectedWorkout.sending(\.workoutSelected)) {
            ForEach(store.workoutCalendar, id: \.self) { item in
                Text(item)
            }
        }
        //        .listStyle(.grouped)
        //        .scrollContentBackground(.hidden)
        //        .padding(.top, 0)/
        //        .padding([.leading, .trailing], 12)
    }
    
    private var contentUnavailable: some View {
        ContentUnavailableView {
            VStack {
                GlassImage("calendar")
                    .font(.largeTitle)
                Text("You haven’t scheduled any workouts yet.")
                    .font(.headline)
            }
        } description: {
            Text("Add your first workout and start planning your activity.")
                .font(.subheadline)
        } actions: {
            GlassButton("plus") {
                // TODO: add action for creating a new workout
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
}
