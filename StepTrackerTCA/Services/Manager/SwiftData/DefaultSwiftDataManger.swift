//
//  DefaultSwiftDataManger.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 26/01/2025.
//

import Foundation
import SwiftData

//final class DefaultSwiftDataManger: SwiftDataManager {
//    
//    // MARK: - Properties
//    
//    lazy var container: ModelContainer = createModelContainer()
//    
//    // MARK: - API
//    
//    @MainActor
//    var mainContext: ModelContext {
//        container.mainContext
//    }
//    
//    func getContext() -> ModelContext {
//        ModelContext(container)
//    }
//    
//    func resetModelContainer() {
//        container.deleteAllData()
//        container = createModelContainer()
//    }
//    
//    // MARK: - Methods
//    
//    private func createModelContainer() -> ModelContainer {
//        do {
//            let config = ModelConfiguration()
//            let container = try ModelContainer(for: CurrentWeightEntity.self,
//                                               configurations: config)
//            return container
//        } catch {
//            fatalError("SwiftDataManager - \(error.localizedDescription)")
//        }
//    }
//    
//}
