//
//  MockData.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 17/01/2025.
//

import Foundation

struct MockData {

    static var steps: [HealthData] {
        var array: [HealthData] = []

        for i in 0..<28 {
            let healthData = HealthData(date: Calendar.current.date(byAdding: .day, value: -i, to: .now)!,
                                      value: .random(in: 4_000...15_000))
            array.append(healthData)
        }

        return array
    }

    static var weights: [HealthData] {
        var array: [HealthData] = []

        for i in 0..<28 {
            let healthData = HealthData(date: Calendar.current.date(byAdding: .day, value: -i, to: .now)!,
                                      value: .random(in: (100 + Double(i/3)...105 + Double(i/3))))
            array.append(healthData)
        }

        return array
    }
    
}
