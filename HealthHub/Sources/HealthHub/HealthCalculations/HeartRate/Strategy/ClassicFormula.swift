//
//  ClassicFormula.swift
//  HealthHub
//
//  Created by Sebastian Ściuba on 28/06/2026.
//

import Foundation

/// Classic max heart rate formula — `220 - age`. Originally attributed to **Fox & Haskell (1971)**.
/// Najprostsza, najbardziej znana, ale **najmniej dokładna statystycznie** spośród nowoczesnych
/// formuł (Tanaka 2001 to standard replacement).
///
/// Reference: Fox SM, Naughton JP, Haskell WL.
/// "Physical activity and the prevention of coronary heart disease."
/// Ann Clin Res. 1971;3(6):404-432.
///
/// Formula: `220 - age`
///
/// Sex-agnostic. Choose this gdy chcesz baseline który każdy zna — np. dla porównań z
/// historicznymi aplikacjami sportowymi.
public struct ClassicFormula: HeartRateFormula {

    public init() {}

    public func maxHR(for age: Int) -> Int {
        220 - age
    }
}
