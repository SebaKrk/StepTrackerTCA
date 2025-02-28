//
//  DefaultWeightGoalServices.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 26/01/2025.
//

import Factory
import Foundation
import Combine

final class DefaultWeightGoalServices: WeightGoalService {
    
    // MARK: - Dependencies

    @LazyInjected(\.recordsRepository) private var recordsRepository
    
    // MARK: - API
    
    func fetchWeightGoal() async throws -> WeightGoal? {
        try? await recordsRepository.fetchWeightGoalWithDate()
    }
    
    func itemsDidChangePublisher() -> AnyPublisher<Void, Never> {
        print("🟢 itemsDidChangePublisher uruchomiony")
        return recordsRepository.itemsDidChangePublisher
            .handleEvents(receiveOutput: { _ in
                print("🔔 Otrzymano powiadomienie o zmianie w repozytorium")
            })
            .eraseToAnyPublisher()
    }
    
}

