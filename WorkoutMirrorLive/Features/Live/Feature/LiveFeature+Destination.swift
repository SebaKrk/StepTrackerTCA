//
//  LiveFeature+Destination.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 03/08/2025.
//

import ComposableArchitecture

/// Implementation of `LiveFeature` destination
extension LiveFeature {
    
    @Reducer
    enum Destination {
        
        /// Represents the destination for displaying in `WorkoutMirroringFeature`.
        case workoutMirroringView(WorkoutMirroringFeature)
        
        /// Represents the destination for displaying in `CalendarFeature`.
        case calendarView(CalendarFeature)
        
        /// Represents the destination for displaying in `WorkoutCreatorFeature`.
        case workoutCreatorView(WorkoutCreatorFeature)
        
        /// Represents the destination for displaying in `WorkoutDevicePickerFeature`.
        case workoutDevicePickerView(WorkoutDevicePickerFeature)
    }
}
