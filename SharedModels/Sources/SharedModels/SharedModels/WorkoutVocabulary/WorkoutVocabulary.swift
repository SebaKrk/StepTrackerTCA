//
//  WorkoutVocabulary.swift
//  SharedModels
//
//  Created by Sebastian Sciuba on 09/02/2026.
//

import Foundation

// MARK: - WorkoutVocabulary

/// A centralized dictionary of workout-related terminology used across the app.
///
/// ## Purpose
///
/// This vocabulary serves multiple consumers:
///
/// 1. **Vision OCR** (`RecognizeDocumentsRequest.textRecognitionOptions.customWords`) —
///    improves text recognition accuracy for handwritten workout notes by providing
///    domain-specific terms that take priority over the built-in dictionary.
///
/// 2. **LLM parsing (Claude API)** — provides structured context and schema
///    for mapping raw OCR text into structured workout data models. Categories help
///    the model understand the semantic meaning of recognized terms.
///
/// 3. **Data model validation** — categories define the valid vocabulary for each field
///    in the workout data model (e.g., only `movement` terms are valid exercise names).
///
/// ## Architecture
///
/// Terms are organized into semantic ``Category`` groups. Each category represents
/// a distinct domain concept in workout planning:
///
/// ```
/// WorkoutVocabulary
/// ├── .format      → AMRAP, EMOM, FOR TIME, REST...
/// ├── .equipment   → KB, DB, BARBELL...
/// ├── .movement    → SQUATS, LUNGES, BURPEES, T2B...
/// ├── .prescription → Rx, RX+, SCALED...
/// └── .unit        → KG, LBS, RPE, RM...
/// ```
///
/// ## Usage
///
/// **Get all words as a flat array (for OCR):**
/// ```swift
/// let customWords = WorkoutVocabulary.allWords
/// request.customWords = customWords
/// ```
///
/// **Get words for a specific category:**
/// ```swift
/// let movements = WorkoutVocabulary.words(for: .movement)
/// ```
///
/// **Get all categories with their terms (for AI context):**
/// ```swift
/// let context = WorkoutVocabulary.allCategorized
/// // [(.format, ["AMRAP", ...]), (.movement, ["SQUATS", ...]), ...]
/// ```
///
/// ## Extending
///
/// To add new terms:
/// 1. Find the appropriate ``Category`` (or create a new one)
/// 2. Add terms to the corresponding array in ``categoryMap``
/// 3. If adding a new category, add a case to ``Category`` and a new entry in ``categoryMap``
///
/// Terms should be added in their most common written form (uppercase for abbreviations,
/// title case for full names). Include both abbreviated and full forms when both are
/// commonly used (e.g., "KB" and "KETTLEBELL").
///
public enum WorkoutVocabulary {

    // MARK: - Category

    /// Semantic categories that group workout terminology by domain concept.
    ///
    /// Each category maps to a distinct field or concept in the workout data model.
    /// This categorization helps both OCR (by providing context-aware vocabulary)
    /// and AI models (by providing structured schema for text-to-model mapping).
    public enum Category: String, CaseIterable, Sendable {

        /// Workout structure formats (e.g., AMRAP, EMOM, FOR TIME).
        ///
        /// Defines how the workout is organized — time domain, rep scheme, or rest structure.
        case format

        /// Training equipment (e.g., KB, DB, BARBELL).
        ///
        /// Physical tools used during exercises. Includes both abbreviations and full names.
        case equipment

        /// Exercise movements (e.g., SQUATS, LUNGES, BURPEES).
        ///
        /// The actual exercises performed. Includes compound names (e.g., "PUSH PRESS")
        /// and abbreviations (e.g., "T2B" for Toes-to-Bar).
        case movement

        /// Workout prescriptions and scaling options (e.g., Rx, SCALED).
        ///
        /// Indicates the intended difficulty level or modification of the workout.
        case prescription

        /// Measurement units (e.g., KG, LBS, RPE).
        ///
        /// Units for weight, intensity, and repetition maximums.
        case unit
    }

    // MARK: - Category Map

    /// The master dictionary mapping each category to its terms.
    ///
    /// This is the single source of truth for all workout vocabulary.
    /// All public accessors (`allWords`, `words(for:)`, etc.) derive from this map.
    ///
    /// - Note: When adding new terms, add them here. Order within each array
    ///   does not matter for OCR, but keeping alphabetical order improves readability.
    private static let categoryMap: [Category: [String]] = [

        .format: [
            "AMRAP",        // As Many Rounds/Reps As Possible
            "EMOM",         // Every Minute On the Minute
            "FOR TIME",
            "REST",
            "TABATA",
            "TC",           // Time Cap
            "TIME CAP",
        ],

        .equipment: [
            "BARBELL",
            "BOX",
            "DB",           // Dumbbell
            "DUMBBELL",
            "KB",           // Kettlebell
            "KETTLEBELL",
            "RING",
            "ROPE",
        ],

        .movement: [
            "AMERICAN SWING",
            "BENCH PRESS",
            "BOTB",         // Burpee Over The Bar
            "BOX JUMP",
            "BURPEE",
            "BURPEE BOX JUMP",
            "BURPEE OVER BAR",
            "BURPEES",
            "CLEAN",
            "CLEAN AND JERK",
            "DEADLIFT",
            "FLOOR PRESS",
            "FRONT SQUATS",
            "GOBLET",
            "HSPU",         // Handstand Push-Up
            "LUNGES",
            "OVERHEAD PRESS",
            "POWER CLEAN",
            "POWER CLEANS",
            "POWER SNATCH",
            "PULL UP",
            "PUSH JERK",
            "PUSH PRESS",
            "PUSHPRESS",
            "REVERSE",
            "RUSSIAN SWING",
            "SNATCH",
            "SQUATS",
            "SWING",
            "T2B",          // Toes-to-Bar
            "THRUSTER",
            "TOES TO BAR",
            "WALL BALL",
        ],

        .prescription: [
            "RX",
            "RX+",
            "Rx",
            "SCALED",
        ],

        .unit: [
            "1RM",          // One-Rep Max
            "CAL",          // Calories
            "KG",
            "LBS",
            "M",            // Meters
            "REP",
            "REPS",
            "RM",           // Rep Max
            "RPE",          // Rate of Perceived Exertion
        ],
    ]

    // MARK: - Public API

    /// All workout terms as a flat array.
    ///
    /// Use this for `RecognizeDocumentsRequest` custom words in Vision OCR.
    ///
    /// ```swift
    /// var request = RecognizeDocumentsRequest()
    /// request.textRecognitionOptions.customWords = WorkoutVocabulary.allWords
    /// ```
    public static var allWords: [String] {
        categoryMap.values.flatMap { $0 }
    }

    /// Returns terms for a specific category.
    ///
    /// ```swift
    /// let movements = WorkoutVocabulary.words(for: .movement)
    /// // ["BOX JUMP", "BURPEES", "CLEAN", ...]
    /// ```
    public static func words(for category: Category) -> [String] {
        categoryMap[category] ?? []
    }

    /// All categories with their terms, useful for providing structured context to AI models.
    ///
    /// Returns an array of tuples `(Category, [String])` ordered by category.
    ///
    /// ```swift
    /// let context = WorkoutVocabulary.allCategorized
    /// for (category, terms) in context {
    ///     print("\(category.rawValue): \(terms.joined(separator: ", "))")
    /// }
    /// ```
    public static var allCategorized: [(category: Category, terms: [String])] {
        Category.allCases.map { category in
            (category: category, terms: words(for: category))
        }
    }

    /// Returns a formatted string description of all categories and their terms.
    ///
    /// Useful as structured context for Foundation Models prompts.
    ///
    /// ```swift
    /// let prompt = """
    /// Parse the following workout text using this vocabulary:
    /// \(WorkoutVocabulary.formattedDescription)
    /// """
    /// ```
    public static var formattedDescription: String {
        allCategorized.map { category, terms in
            "\(category.rawValue): \(terms.joined(separator: ", "))"
        }
        .joined(separator: "\n")
    }
}
