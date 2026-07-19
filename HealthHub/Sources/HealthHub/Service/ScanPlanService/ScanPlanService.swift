//
//  ScanPlanService.swift
//  HealthHub
//
//  Created by Sebastian Sciuba on 07/02/2026.
//

import Foundation
import SharedModels
import UIKit
import Vision

/// Actor responsible for recognizing text from images using Vision document OCR.
///
/// Uses `RecognizeDocumentsRequest` (iOS 26+) instead of the flat
/// `RecognizeTextRequest`: the document observation keeps multi-line paragraphs
/// together and returns tables/lists as structure, so an exercise never gets
/// detached from its sets and weights before the text reaches the LLM.
public actor ScanPlanService {

    public init() {}

    /// Recognizes text from raw image data, preserving document structure.
    /// - Parameter imageData: Raw image data (HEIC, JPEG, PNG).
    /// - Returns: Serialized document text — paragraphs as-is, table rows with
    ///   cells joined by `|`, list items prefixed with `-`.
    public func recognizeText(from imageData: Data) async throws -> String {
        guard let uiImage = UIImage(data: imageData),
              let cgImage = uiImage.cgImage else {
            throw ScanPlanServiceError.invalidImage
        }

        var request = RecognizeDocumentsRequest()

        // Document recognition supports fewer languages than plain text OCR —
        // requesting an unsupported one makes perform(on:) throw for EVERY
        // image, so intersect our preference with what the request supports.
        let preferredLanguages = [Locale.Language(identifier: "pl"), Locale.Language(identifier: "en")]
        let supportedCodes = Set(
            request.supportedRecognitionLanguages.compactMap { $0.languageCode?.identifier }
        )
        let languages = preferredLanguages.filter { language in
            language.languageCode.map { supportedCodes.contains($0.identifier) } ?? false
        }
        if !languages.isEmpty {
            request.textRecognitionOptions.recognitionLanguages = languages
            // Auto-detection overrides the language list on messy handwriting
            // and hallucinates Cyrillic/CJK fragments (seen on whiteboard
            // photos) — workout plans here are only ever Polish/English.
            request.textRecognitionOptions.automaticallyDetectLanguage = false
        }
        request.textRecognitionOptions.useLanguageCorrection = true
        request.textRecognitionOptions.customWords = WorkoutVocabulary.allWords

        let observations = try await request.perform(on: cgImage)

        let recognizedText = observations
            .map { serialize(document: $0.document) }
            .joined(separator: "\n\n")

        guard !recognizedText.isEmpty else {
            throw ScanPlanServiceError.noTextFound
        }

        #if DEBUG
        print("📄 [ScanPlanService] Serialized document:\n\(recognizedText)")
        #endif

        return recognizedText
    }

    // MARK: - Serialization

    /// Flattens a recognized document into LLM-friendly text without losing
    /// the relations the flat OCR used to break: a table row stays one line
    /// (exercise | sets | weight), a wrapped paragraph stays one block.
    private func serialize(document: DocumentObservation.Container) -> String {
        var blocks: [String] = []

        if let title = document.title {
            blocks.append(title.transcript)
        }

        for paragraph in document.paragraphs {
            // The title shows up again among paragraphs — skip the duplicate
            // (observed: "CROSS FIT" heading emitted twice).
            guard paragraph.transcript != document.title?.transcript else { continue }
            blocks.append(paragraph.transcript)
        }

        for table in document.tables {
            let rows = table.rows.map { row in
                row
                    .map { cell in
                        cell.content.text.transcript
                            .replacingOccurrences(of: "\n", with: " ")
                    }
                    .joined(separator: " | ")
            }
            blocks.append(rows.joined(separator: "\n"))
        }

        for list in document.lists {
            let items = list.items.map { "- \($0.itemString)" }
            blocks.append(items.joined(separator: "\n"))
        }

        return blocks
            .filter { !$0.isEmpty }
            .joined(separator: "\n\n")
    }
}

// MARK: - Errors

/// Errors that can occur during scan plan OCR processing.
public enum ScanPlanServiceError: LocalizedError {
    case invalidImage
    case noTextFound

    public var errorDescription: String? {
        switch self {
        case .invalidImage:
            String(localized: "Could not process the selected image.")
        case .noTextFound:
            String(localized: "No text was found in the image.")
        }
    }
}
