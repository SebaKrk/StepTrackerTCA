//
//  FairbarnUnknownFormula.swift
//  HealthHub
//
//  Created by Sebastian Sciuba on 25/09/2025.
//

import Foundation

public struct FairbarnUnknownFormula: HeartRateFormula {
    
    public init() {}
    
    public func maxHR(for age: Int) -> Int {
        220 - age
    }
}
