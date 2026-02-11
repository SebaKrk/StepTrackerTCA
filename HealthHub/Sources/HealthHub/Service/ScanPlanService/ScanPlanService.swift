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

/// Actor responsible for recognizing text from images using Vision OCR.
public actor ScanPlanService {

    public init() {}

    /// Recognizes text from raw image data.
    /// - Parameter imageData: Raw image data (HEIC, JPEG, PNG).
    /// - Returns: Recognized text with lines joined by newlines.
    public func recognizeText(from imageData: Data) async throws -> String {
        guard let uiImage = UIImage(data: imageData),
              let cgImage = uiImage.cgImage else {
            throw ScanPlanServiceError.invalidImage
        }

        var request = RecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
//        request.recognitionLanguages = ["en-US", "pl-PL"]
        request.customWords = WorkoutVocabulary.allWords

        let observations = try await request.perform(on: cgImage)

        let recognizedText = observations
            .compactMap { observation -> String? in
                guard let candidate = observation.topCandidates(1).first,
                      candidate.confidence > 0.3 else {
                    return nil
                }
                return candidate.string
            }
            .joined(separator: "\n")

        guard !recognizedText.isEmpty else {
            throw ScanPlanServiceError.noTextFound
        }

        return recognizedText
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
