//
//  FairbarnFemaleFormula.swift
//  HealthHub
//
//  Created by Sebastian Sciuba on 25/09/2025.
//

import Foundation

public struct FairbarnFemaleFormula: HeartRateFormula {
    
    public init() {}
    
    public func maxHR(for age: Int) -> Int {
        209 - Int(0.86 * Double(age))
    }
}
