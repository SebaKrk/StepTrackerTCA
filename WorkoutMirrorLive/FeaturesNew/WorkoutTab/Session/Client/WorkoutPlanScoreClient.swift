//
//  WorkoutPlanScoreClient.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 03/03/2026.
//

import ComposableArchitecture
import Foundation
import SharedModels

// MARK: - Client

struct WorkoutPlanScoreClient: Sendable {

    // MARK: - Operations

    /// Saves a workout plan score. If a record with the same `id` already exists, it is replaced (upsert).
    var save: @Sendable (WorkoutPlanScore) async throws -> Void

    /// Returns all executions of a given training plan, sorted by date descending.
    var fetchByTrainingSessionId: @Sendable (UUID) async throws -> [WorkoutPlanScore]

    /// Returns the execution record linked to a specific HKWorkout, or `nil` if none exists.
    var fetchByHKWorkoutId: @Sendable (UUID) async throws -> WorkoutPlanScore?
}

// MARK: - DependencyValues

extension DependencyValues {
    var workoutPlanScoreClient: WorkoutPlanScoreClient {
        get { self[WorkoutPlanScoreClientKey.self] }
        set { self[WorkoutPlanScoreClientKey.self] = newValue }
    }
}

// MARK: - DependencyKey

private enum WorkoutPlanScoreClientKey: DependencyKey {

    // ⚠️ TYMCZASOWA IMPLEMENTACJA — IOS-00070-B2
    //
    // liveValue używa pliku JSON w Application Support jako tymczasowego storage.
    // MUSI zostać zastąpiony CoreData + CloudKit zanim aplikacja trafi do produkcji.
    //
    // Problemy tej implementacji:
    //   - Ładuje WSZYSTKIE rekordy do pamięci przy każdym fetch (fetchAll + filter)
    //   - Brak synchronizacji między urządzeniami
    //   - Brak migracji danych
    //
    // Docelowe rozwiązanie: NSPersistentCloudKitContainer (IOS-00070-B2)
    //   - Index na hkWorkoutId → efektywny fetch przy setkach rekordów
    //   - CloudKit → automatyczny sync iPhone ↔ iPad ↔ Watch
    static let liveValue: WorkoutPlanScoreClient = {
        let store = WorkoutPlanScoreStore()
        return WorkoutPlanScoreClient(
            save: { score in
                try await store.upsert(score)
            },
            fetchByTrainingSessionId: { id in
                try await store.fetchByTrainingSessionId(id)
            },
            fetchByHKWorkoutId: { id in
                try await store.fetchByHKWorkoutId(id)
            }
        )
    }()

    static var testValue: WorkoutPlanScoreClient {
        WorkoutPlanScoreClient(
            save: unimplemented("WorkoutPlanScoreClient.save"),
            fetchByTrainingSessionId: unimplemented("WorkoutPlanScoreClient.fetchByTrainingSessionId"),
            fetchByHKWorkoutId: unimplemented("WorkoutPlanScoreClient.fetchByHKWorkoutId")
        )
    }
}

// MARK: - Temporary JSON Store

// ⚠️ TYMCZASOWY AKTOR — USUNĄĆ przy implementacji IOS-00070-B2
//
// Zapis do pliku JSON jest rozwiązaniem prototypowym.
// Nie używać jako wzorca dla innych klientów wymagających persystencji.
private actor WorkoutPlanScoreStore {

    // MARK: - Properties

    private let fileURL: URL

    // MARK: - Init

    init() {
        let appSupport = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first!
        self.fileURL = appSupport.appendingPathComponent("workoutPlanScores.json")
    }

    // MARK: - Operations

    func upsert(_ score: WorkoutPlanScore) throws {
        var all = try load()
        if let index = all.firstIndex(where: { $0.id == score.id }) {
            all[index] = score
        } else {
            all.append(score)
        }
        try persist(all)
    }

    func fetchByTrainingSessionId(_ id: UUID) throws -> [WorkoutPlanScore] {
        try load()
            .filter { $0.trainingSessionId == id }
            .sorted { $0.date > $1.date }
    }

    func fetchByHKWorkoutId(_ id: UUID) throws -> WorkoutPlanScore? {
        try load().first { $0.hkWorkoutId == id }
    }

    // MARK: - Private

    private func load() throws -> [WorkoutPlanScore] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return [] }
        let data = try Data(contentsOf: fileURL)
        return try JSONDecoder().decode([WorkoutPlanScore].self, from: data)
    }

    private func persist(_ scores: [WorkoutPlanScore]) throws {
        let data = try JSONEncoder().encode(scores)
        try data.write(to: fileURL, options: .atomic)
    }
}
