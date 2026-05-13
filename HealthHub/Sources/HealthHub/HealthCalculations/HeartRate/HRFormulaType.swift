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

    /// Fairbarn — sex-aware general population. Selects between
    /// `FairbarnMaleFormula`, `FairbarnFemaleFormula`, or `FairbarnUnknownFormula`
    /// based on `biologicalSex`.
    case fairbarn

    /// Classic (`220 - age`) — simplest baseline, sex-agnostic.
    case classic
}
