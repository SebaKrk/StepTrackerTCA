//
//  FairbarnMaleFormula.swift
//  HealthHub
//
//  Created by Sebastian Sciuba on 25/09/2025.
//

import Foundation

public struct FairbarnMaleFormula: HeartRateFormula {
    
    public init() {}
    
    public func maxHR(for age: Int) -> Int {
        207 - Int(0.78 * Double(age))
    }
}
