//
//  HRFormulaType.swift
//  HealthHub
//
//  Created by Sebastian Sciuba on 08/05/2026.
//

import Foundation

/// Selects which max-heart-rate formula `HeartRateCalculator` should apply.
///
/// Used as the **primary selector** in the Strategy Pattern — `biologicalSex` is
/// only consulted when the chosen formula is sex-aware (e.g., `.fairbarn`).
///
/// Adding a new formula = add a new case here + add the corresponding `HeartRateFormula`
/// implementation + extend the switch in `DefaultHeartRateCalculator.selectStrategy`.
public enum HRFormulaType: String, CaseIterable, Sendable, Codable {

    /// Nes 2013 (`211 - 0.64 × age`) — sex-agnostic, calibrated for active populations.
    case nes

    /// Tanaka 2001 (`208 - 0.7 × age`) — sex-agnostic, modern statistical replacement
    /// for Classic. Recommended default dla general population (Apple Health baseline).
    case tanaka

    /// Gulati 2010 (`206 - 0.88 × age`) — calibrated specifically dla **kobiet**.
    /// Sex-agnostic implementation, ale rekomendowana primarily dla kobiet
    /// (Classic/Tanaka overestimate ich maxHR).
    case gulati

    /// Fairbarn — sex-aware general population. Selects between
    /// `FairbarnMaleFormula`, `FairbarnFemaleFormula`, or `FairbarnUnknownFormula`
    /// based on `biologicalSex`.
    case fairbarn

    /// Classic (`220 - age`) — Fox & Haskell 1971, simplest baseline, sex-agnostic.
    /// Najmniej dokładna statystycznie ale najbardziej rozpoznawalna.
    case classic
}
