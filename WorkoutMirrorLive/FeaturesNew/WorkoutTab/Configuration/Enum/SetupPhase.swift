//
//  SetupPhase.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 23/08/2025.
//

import Foundation

enum SetupPhase: Equatable, Identifiable, CaseIterable {
    
    /// wybór: watch / iPhone / mirror
    case device 
    
    /// crossfit / functional / box
    case activity
    
    /// QuickStart | Scan | Manual
    //case plan
    
    /// podsumowanie: co wyjdzie z planu
    // case preview
    
    /// sygnał do startu (GO)
    case ready
    
    var id : Self { self }
    
}

extension SetupPhase {
    
    var navTitle: String {
        switch self {
            
        case .device: return "Chose device"
        case .activity: return "Chose activity"
        case .ready: return ""
        }
    }
}
