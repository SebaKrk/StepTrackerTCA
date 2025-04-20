//
//  WorkoutData.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 12/01/2025.
//

import Foundation

struct WorkoutData: Identifiable, Hashable {
    let id = UUID()
    let image: String
    let title: String
    let subtitle: String
    let date: Date
    let kcal: Double
    
    static var mockData: [WorkoutData] {
        var array: [WorkoutData] = []
        for i in 0..<28 {
            let workout = WorkoutData(image: "figure.run", title: "Run \(i)", subtitle: "Trial run", date: .now, kcal: 1_000)
            array.append(workout)
        }
        return array
    }
    
}
