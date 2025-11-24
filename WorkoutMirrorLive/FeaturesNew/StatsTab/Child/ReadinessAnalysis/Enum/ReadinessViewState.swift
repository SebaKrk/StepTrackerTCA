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
    
    /// Stream partial response - pokazujemy tekst na bieżąco
    case streaming(String)
    
    /// Finalna odpowiedź z modelu
    case completed(String)
    
    /// Fake response gdy AI niedostępne (możesz testować tłumaczenie)
    case mockResponse(String)
    
    /// Error state
    case failed(String)
}
