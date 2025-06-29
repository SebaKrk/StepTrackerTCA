//
//  DefaultImageAnalysisService.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 27/06/2025.
//

import Foundation
import UIKit
import SwiftUI
@preconcurrency import Vision

final class DefaultImageAnalysisService: ImageAnalysisService {
   
    func performOCR(on image: UIImage) async throws -> [RecognizedTextObservation] {
        guard let imageData = image.jpegData(compressionQuality: 1.0) else {
            throw OCRError.invalidImage
        }
        
        let ocr = OCR()
        try await ocr.performOCR(imageData: imageData)
        
        return ocr.observations
    }
}


//final class DefaultImageAnalysisService: ImageAnalysisService {
//   
//    func performOCR(on image: UIImage) async throws -> String {
//        guard let imageData = image.jpegData(compressionQuality: 1.0) else {
//            throw OCRError.invalidImage
//        }
//        
//        let ocr = OCR()
//        try await ocr.performOCR(imageData: imageData)
//        
//        // Pobierz tekst z obserwacji
//        let recognizedStrings = ocr.observations.compactMap { observation in
//            observation.topCandidates(1).first?.string
//        }
//        
//        return recognizedStrings.joined(separator: "\n")
//    }
//}

// MARK: - OCR Class (z SampleTextScanner)
@Observable
class OCR {
    /// The array of `RecognizedTextObservation` objects to hold the request's results.
    var observations = [RecognizedTextObservation]()

    /// The Vision request.
    var request = RecognizeTextRequest()

    func performOCR(imageData: Data) async throws {
        /// Clear the `observations` array for photo recapture.
        observations.removeAll()

        /// Perform the request on the image data and return the results.
        let results = try await request.perform(on: imageData)

        /// Add each observation to the `observations` array.
        for observation in results {
            observations.append(observation)
        }
    }
}

/// Create and dynamically size a bounding box.
struct Box: Shape {
    private let normalizedRect: NormalizedRect

    init(observation: any BoundingBoxProviding) {
        normalizedRect = observation.boundingBox
    }

    func path(in rect: CGRect) -> Path {
        let rect = normalizedRect.toImageCoordinates(rect.size, origin: .upperLeft)
        return Path(rect)
    }
}

