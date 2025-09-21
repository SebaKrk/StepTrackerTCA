//
//  SetupPhase.swift
//  SharedModels
//
//  Created by Sebastian Sciuba on 21/09/2025.
//

import Foundation

public enum SetupPhase: Equatable, Identifiable, CaseIterable {
    
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
    
    public var id : Self { self }
    
}

extension SetupPhase {
    
    public var navTitle: String {
        
        switch self {
        case .device: return "Chose device"
        case .activity: return "Chose activity"
        case .ready: return ""
        }
    }
    
}
