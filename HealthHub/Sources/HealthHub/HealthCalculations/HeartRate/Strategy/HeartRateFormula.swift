//
//  HeartRateFormula.swift
//  HealthHub
//
//  Created by Sebastian Sciuba on 25/09/2025.
//

import Foundation

public protocol HeartRateFormula {
    
    func maxHR(for age: Int) -> Int
    
}
