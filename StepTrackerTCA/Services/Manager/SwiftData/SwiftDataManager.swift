//
//  SwiftDataManager.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 26/01/2025.
//

import Foundation
import SwiftData

protocol SwiftDataManager {
    
    var container: ModelContainer { get set }
    
    var mainContext: ModelContext { get }
    
    func resetModelContainer()
    
    func getContext() -> ModelContext
    
}

