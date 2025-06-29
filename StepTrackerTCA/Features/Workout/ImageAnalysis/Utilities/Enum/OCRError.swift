//
//  OCRError.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 27/06/2025.
//

import Foundation

enum OCRError: Error, LocalizedError {
    case invalidImage
    case noRectanglesFound
    case noWhiteboardDetected
    
    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Invalid image format"
        case .noRectanglesFound:
            return "No rectangles found in image"
        case .noWhiteboardDetected:
            return "No whiteboard detected in image"
        }
    }
}
