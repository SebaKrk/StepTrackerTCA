//
//  CoreDataManager.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 24/02/2025.
//

import CoreData
import Foundation

public final class CoreDataManager {
    
    // MARK: - Properties
    
    private let container: NSPersistentContainer
    
    // MARK: - Lifecycle
    
    public init(persistentContainer: NSPersistentContainer? = nil) {
        if let persistentContainer {
            container = persistentContainer
            return
        }
        
        guard let modelURL = Bundle.main.url(forResource: "StepTrackerModel", withExtension: "momd") else {
            fatalError("Database model not found.")
        }
        
        guard let model = NSManagedObjectModel(contentsOf: modelURL) else {
            fatalError("Unable to load model.")
        }
        
        container = NSPersistentContainer(name: "StepTrackerModel", managedObjectModel: model)
        container.loadPersistentStores { _, error in
            if let error {
                fatalError("Error when loading persistent store: \(error)")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
    
    // MARK: - API
    
    public var viewContext: NSManagedObjectContext {
        container.viewContext
    }
    
    public var backgroundContext: NSManagedObjectContext {
        container.newBackgroundContext()
    }
    
}
