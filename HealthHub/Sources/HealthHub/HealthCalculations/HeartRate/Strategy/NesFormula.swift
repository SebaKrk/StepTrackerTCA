//
//  NesFormula.swift
//  HealthHub
//
//  Created by Sebastian Sciuba on 08/05/2026.
//

import Foundation

/// Nes 2013 max heart rate formula, calibrated for **active populations**.
///
/// Reference: Nes BM, Janszky I, Wisløff U, Støylen A, Karlsen T.
/// "Age-predicted maximal heart rate in healthy subjects: The HUNT Fitness Study."
/// Scand J Med Sci Sports. 2013.
///
/// Formula: `211 - 0.64 × age`
///
/// Sex-agnostic — applicable to active men and women.
public struct NesFormula: HeartRateFormula {

    public init() {}

    public func maxHR(for age: Int) -> Int {
        211 - Int(0.64 * Double(age))
    }
}
