//
//  OCRError.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 27/06/2025.
//

import Foundation

enum OCRError: Error {
    case invalidImage
    case processingFailed
    case noTextFound
    
    var localizedDescription: String {
        switch self {
        case .invalidImage:
            return "Nieprawidłowy obraz"
        case .processingFailed:
            return "Błąd przetwarzania OCR"
        case .noTextFound:
            return "Nie znaleziono tekstu w obrazie"
        }
    }
}
