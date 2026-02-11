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

    /// Image selected, ready to extract text.
    case imageSelected

    /// OCR text recognition in progress.
    case processingOCR

    /// Text successfully extracted and ready for editing.
    case textReady

    /// An error occurred during image loading or OCR.
    case failed(String)
}
