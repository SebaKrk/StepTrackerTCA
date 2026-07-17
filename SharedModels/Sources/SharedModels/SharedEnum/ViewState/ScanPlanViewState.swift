//
//  ScanPlanViewState.swift
//  SharedModels
//
//  Created by Sebastian Sciuba on 07/02/2026.
//

import Foundation

/// Represents the current state of the scan plan OCR flow.
public enum ScanPlanViewState: Equatable {

    /// No image selected yet.
    case idle

    /// Photo picked, loading its data from the library (may download from iCloud).
    case loadingPhoto

    /// OCR text recognition in progress.
    case processingOCR

    /// Text successfully extracted and ready for editing.
    case textReady

    /// An error occurred during image loading, OCR, or parsing.
    case failed(String)
}
