//
//  HistoricalDataPoint.swift
//  SharedModels
//
//  Created by Sebastian Sciuba on 10/01/2026.
//

import Foundation

/// Model dla pojedynczego punktu danych historycznych
public struct HistoricalDataPoint: Identifiable, Sendable, Equatable {
    
    public let id: UUID
    
    public let date: Date
    
    public let value: Double  // Surowa wartość (np. HRV w ms, RHR w bpm)
    
    public init(id: UUID = UUID(), date: Date, value: Double) {
        self.id = id
        self.date = date
        self.value = value
    }
}
