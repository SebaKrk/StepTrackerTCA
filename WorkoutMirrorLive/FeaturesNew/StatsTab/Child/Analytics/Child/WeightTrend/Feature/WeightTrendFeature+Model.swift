//
//  WeightTrendFeature+Model.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 16/04/2026.
//

import Foundation

extension WeightTrendFeature {

    /// A single daily weight measurement.
    struct WeightDataPoint: Identifiable, Equatable {
        var id: Date { date }
        let date: Date
        let weight: Double
    }
}
