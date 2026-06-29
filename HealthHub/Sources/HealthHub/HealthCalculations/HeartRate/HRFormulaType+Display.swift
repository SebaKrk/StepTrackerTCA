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
        case .classic:  return "Klasyczna"
        }
    }

    // MARK: - Formula text (footnote)

    /// Wzór matematyczny do pokazania jako footnote pod nazwą formuły.
    /// Używa polskiego "wiek" zamiast angielskiego "age" + UTF-8 minus zamiast ASCII hyphen.
    var formulaText: String {
        switch self {
        case .nes:      return "211 − 0,64 × wiek"
        case .tanaka:   return "208 − 0,7 × wiek"
        case .gulati:   return "206 − 0,88 × wiek"
        case .fairbarn: return "207 − 0,78 × wiek (mężczyźni) / wariant dla kobiet"
        case .classic:  return "220 − wiek"
        }
    }

    // MARK: - Target audience (badge / tag)

    /// Krótki tag do badge'a — "dla kogo" jest ta formuła. Może być użyty jako label
    /// w pill-style badge obok title.
    var targetAudience: String {
        switch self {
        case .nes:      return "Aktywni"
        case .tanaka:   return "Ogólna populacja"
        case .gulati:   return "Kobiety"
        case .fairbarn: return "Uwzględnia płeć"
        case .classic:  return "Uniwersalna"
        }
    }

    // MARK: - Full description (info row / settings detail)

    /// Pełny opis do Settings info row — kiedy używać, dla kogo, accuracy notes.
    /// 1-2 zdania, język neutralny ale informacyjny.
    var description: String {
        switch self {
        case .nes:
            return "Skalibrowana dla osób regularnie trenujących. Z badania HUNT Fitness Study (Norwegia, 2013). Wyższa wartość niż formuły dla ogólnej populacji — odzwierciedla lepsze przygotowanie."
        case .tanaka:
            return "Nowoczesny statystyczny zastępca formuły klasycznej. Walidowana na 18 712 osobach. Rekomendowana dla ogólnej populacji — Apple Health używa jej jako baseline."
        case .gulati:
            return "Dostosowana dla kobiet — klasyczna formuła zawyżała ich maksymalne tętno. Z badania St. James Women Take Heart Project (2010, 5437 kobiet). Daje niższe wartości — bardziej realistyczne dla większości kobiet."
        case .fairbarn:
            return "Uwzględnia biologiczną płeć z HealthKit. Mężczyźni: 207 − 0,78 × wiek; kobiety: osobny wariant. Dobry kompromis gdy chcesz dokładności dopasowanej do płci."
        case .classic:
            return "Najstarsza i najprostsza — wzór Fox i Haskell z 1971 roku. Łatwa do zapamiętania, ale najmniej dokładna statystycznie. Wybierz jeśli chcesz wartość porównywalną z historycznymi aplikacjami fitness."
        }
    }
}
