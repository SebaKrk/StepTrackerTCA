//
//  FairbarnFemaleFormula.swift
//  HealthHub
//
//  Created by Sebastian Sciuba on 25/09/2025.
//

import Foundation

public struct FairbarnFemaleFormula: HeartRateFormula {
    
    public func maxHR(for age: Int) -> Int {
        208 - Int(0.7 * Double(age))
    }
}

