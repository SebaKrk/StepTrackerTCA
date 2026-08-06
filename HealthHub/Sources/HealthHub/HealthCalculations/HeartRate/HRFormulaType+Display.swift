//
//  HRFormulaType+Display.swift
//  HealthHub
//
//  Created by Sebastian Ściuba on 28/06/2026.
//
//  UI-facing metadata dla każdej formuły — gotowe do prezentacji w Settings Picker,
//  badge'ach z target audience, formula text footnote i pełnym opisie.
//
//  Stringi po polsku (default language projektu). Future: gdy będzie EN, można dodać
//  `Bundle.module` + Localizable.xcstrings w HealthHub package resources.

import Foundation
import SharedModels

public extension HRFormulaType {

    // MARK: - Availability per biological sex

    /// Czy ta formuła ma sens dla podanej płci biologicznej. Gulati jest dedykowana
    /// dla kobiet — Fox/Tanaka overestimate ich maxHR — więc nie pokazujemy jej mężczyznom
    /// w UI (świadoma decyzja: UX > matematyczna stosowalność).
    ///
    /// Pozostałe formuły są sex-agnostic albo same handle'ują biologicalSex (Fairbarn).
    func isAvailable(for biologicalSex: BiologicalSex) -> Bool {
        switch self {
        case .gulati:
            return biologicalSex != .male
        case .nes, .tanaka, .fairbarn, .classic:
            return true
        }
    }

    /// Lista formuł dostępnych dla podanej płci. Convenience helper dla UI (`ForEach`).
    static func availableCases(for biologicalSex: BiologicalSex) -> [HRFormulaType] {
        allCases.filter { $0.isAvailable(for: biologicalSex) }
    }
}

public extension HRFormulaType {

    // MARK: - Display name (Picker label)

    /// Krótka nazwa do wyświetlenia w UI (Picker option label).
    var title: String {
        switch self {
        case .nes:      return "Nes 2013"
        case .tanaka:   return "Tanaka 2001"
        case .gulati:   return "Gulati 2010"
        case .fairbarn: return "Fairbarn"
        case .classic:  return String(localized: "Classic")
        }
    }

    // MARK: - Formula text (footnote)

    /// Wzór matematyczny do pokazania jako footnote pod nazwą formuły.
    /// Używa polskiego "wiek" zamiast angielskiego "age" + UTF-8 minus zamiast ASCII hyphen.
    var formulaText: String {
        switch self {
        case .nes:      return String(localized: "211 − 0.64 × age")
        case .tanaka:   return String(localized: "208 − 0.7 × age")
        case .gulati:   return String(localized: "206 − 0.88 × age")
        case .fairbarn: return String(localized: "207 − 0.78 × age (men) / women's variant")
        case .classic:  return String(localized: "220 − age")
        }
    }

    // MARK: - Target audience (badge / tag)

    /// Krótki tag do badge'a — "dla kogo" jest ta formuła. Może być użyty jako label
    /// w pill-style badge obok title.
    var targetAudience: String {
        switch self {
        case .nes:      return String(localized: "Active people")
        case .tanaka:   return String(localized: "General population")
        case .gulati:   return String(localized: "Women")
        case .fairbarn: return String(localized: "Sex-aware")
        case .classic:  return String(localized: "Universal")
        }
    }

    // MARK: - Full description (info row / settings detail)

    /// Pełny opis do Settings info row — kiedy używać, dla kogo, accuracy notes.
    /// 1-2 zdania, język neutralny ale informacyjny.
    var description: String {
        switch self {
        case .nes:
            return String(localized: "Calibrated for people who train regularly. From the HUNT Fitness Study (Norway, 2013). Higher values than general-population formulas — reflects better conditioning.")
        case .tanaka:
            return String(localized: "The modern statistical replacement for the classic formula. Validated on 18,712 people. Recommended for the general population — Apple Health uses it as the baseline.")
        case .gulati:
            return String(localized: "Adjusted for women — the classic formula overestimated their max heart rate. From the St. James Women Take Heart Project (2010, 5,437 women). Gives lower, more realistic values for most women.")
        case .fairbarn:
            return String(localized: "Takes HealthKit biological sex into account. Men: 207 − 0.78 × age; women: a separate variant. A good compromise when you want sex-specific accuracy.")
        case .classic:
            return String(localized: "The oldest and simplest — the 1971 Fox and Haskell formula. Easy to remember but statistically the least accurate. Pick it for values comparable with legacy fitness apps.")
        }
    }
}
