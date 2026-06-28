//
//  GulatiFormula.swift
//  HealthHub
//
//  Created by Sebastian Ściuba on 28/06/2026.
//

import Foundation

/// Gulati et al. (2010) max heart rate formula, calibrated specifically for **women**.
/// Fox/Tanaka overestimate maxHR for women — Gulati corrected this after analyzing
/// **5,437 women** in the St. James Women Take Heart Project.
///
/// Reference: Gulati M, Shaw LJ, Thisted RA, Black HR, Bairey Merz CN, Arnsdorf MF.
/// "Heart rate response to exercise stress testing in asymptomatic women."
/// Circulation. 2010;122(2):130-137.
///
/// Formula: `206 - 0.88 × age`
///
/// **Sex-agnostic implementation** — formula is mathematically applied regardless of
/// biological sex. Recommended primarily for women; men selecting it get a more
/// conservative estimate than Tanaka/Nes.
public struct GulatiFormula: HeartRateFormula {

    public init() {}

    public func maxHR(for age: Int) -> Int {
        206 - Int(0.88 * Double(age))
    }
}
