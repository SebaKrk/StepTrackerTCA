//
//  PREntryEditorFeatureTests.swift
//  WorkoutMirrorLiveTests
//
//  Created by Sebastian Ściuba on 01/09/2026.
//

import ComposableArchitecture
import Foundation
import SharedModels
import Testing

@testable import WorkoutMirrorLive

@MainActor
struct PREntryEditorFeatureTests {

    /// Fixed reference date — fixtures never use `.now` (lessons.md).
    private static let fixedNow = Date(timeIntervalSince1970: 1_756_684_800)

    @Test
    func saveFlowPersistsEntryAndDismisses() async throws {
        let movement = try #require(PRCatalog.movement(id: "back-squat"))
        let savedEntry = LockIsolated<PREntry?>(nil)
        let didDismiss = LockIsolated(false)

        let store = TestStore(
            initialState: PREntryEditorFeature.State(movement: movement, now: Self.fixedNow)
        ) {
            PREntryEditorFeature()
        } withDependencies: {
            $0.prEntryClient.save = { entry in savedEntry.setValue(entry) }
            $0.personalDataClient = PersonalDataClient(
                getAge: { nil },
                getBiologicalSex: { nil },
                getHeight: { nil },
                getWeight: { _ in nil },
                getWeightForDate: { _ in nil },
                getRestingHeartRate: { _ in nil }
            )
            $0.uuid = .incrementing
            $0.date = .constant(Self.fixedNow)
            $0.dismiss = DismissEffect { didDismiss.setValue(true) }
        }

        await store.send(\.binding.weightText, "150") {
            $0.weightText = "150"
        }
        await store.send(\.view.saveTapped)
        await store.finish()

        let entry = try #require(savedEntry.value)
        #expect(entry.movementId == "back-squat")
        #expect(entry.score == .weight(kilograms: 150))
        #expect(entry.context == .fresh)
        #expect(entry.bodyWeightKg == nil)
        #expect(didDismiss.value)
    }

    @Test
    func zeroWeightDisablesSave() async throws {
        let movement = try #require(PRCatalog.movement(id: "back-squat"))

        let store = TestStore(
            initialState: PREntryEditorFeature.State(movement: movement, now: Self.fixedNow)
        ) {
            PREntryEditorFeature()
        }

        await store.send(\.binding.weightText, "0") {
            $0.weightText = "0"
        }

        #expect(store.state.isSaveDisabled)
    }
}
