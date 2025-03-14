//
//  WorkoutCategory.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 13/03/2025.
//
import Foundation

protocol WorkoutCategory: CaseIterable, RawRepresentable where RawValue == String {
    
    var title: String { get }
    
    var description: String { get }
    
    var movementType: any MovementType.Type { get }
    
}
