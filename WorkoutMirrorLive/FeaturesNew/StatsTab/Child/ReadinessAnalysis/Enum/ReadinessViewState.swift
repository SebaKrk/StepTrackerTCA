//
//  ReadinessViewState.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 22/11/2025.
//

import Foundation

enum ReadinessViewState: Equatable {
    /// Początkowy stan - nic się jeszcze nie dzieje
    case idle
    
    /// Model myśli - pokazujemy spinner
    case thinking
    
    /// Stream partial response - tekst generowany na bieżąco
    case streaming
    
    /// Finalna odpowiedź z modelu
    case completed
    
    /// Fake response gdy AI niedostępne
    case mockResponse
    
    /// Error state
    case failed(String)
}
