//
//  TanakaFormula.swift
//  HealthHub
//
//  Created by Sebastian Ściuba on 28/06/2026.
//

import Foundation

/// Tanaka et al. (2001) max heart rate formula — modern statistical replacement
/// for the classic `220 - age` (Fox 1971). Validated on **18,712 subjects** in
/// meta-analysis.
///
/// Reference: Tanaka H, Monahan KD, Seals DR.
/// "Age-predicted maximal heart rate revisited."
/// J Am Coll Cardiol. 2001;37(1):153-156.
///
/// Formula: `208 - 0.7 × age`
///
/// Sex-agnostic — recommended default for general population (Apple Health & Fitness
/// platforms use this as their internal baseline).
public struct TanakaFormula: HeartRateFormula {

    public init() {}

    public func maxHR(for age: Int) -> Int {
        208 - Int(0.7 * Double(age))
    }
}
