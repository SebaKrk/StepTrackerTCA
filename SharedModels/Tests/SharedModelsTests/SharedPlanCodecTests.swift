//
//  SharedPlanCodecTests.swift
//  SharedModels
//
//  Created by Sebastian Ściuba on 13/07/2026.
//

import Foundation
import Testing
@testable import SharedModels

@Suite("SharedPlanCodec")
struct SharedPlanCodecTests {

    private let exportedAt = Date(timeIntervalSince1970: 1_700_000_000)

    /// Preview fixture uses `.now` (fractional seconds), but the codec's ISO 8601
    /// date strategy stores whole seconds only — a round-trip fixture must use
    /// a whole-second date or equality fails on sub-second precision.
    private var fixedDatePlan: TrainingSession {
        let preview = TrainingSession.previewTrainingSession
        return TrainingSession(
            id: preview.id,
            date: Date(timeIntervalSince1970: 1_700_000_000),
            title: preview.title,
            activity: preview.activity,
            location: preview.location,
            warmUp: preview.warmUp,
            workouts: preview.workouts,
            coolDown: preview.coolDown
        )
    }

    @Test("round-trip preserves the plan")
    func roundTrip() throws {
        let plan = fixedDatePlan
        let encoded = try SharedPlanCodec.encode(plan: plan, exportedAt: exportedAt)
        let decoded = try SharedPlanCodec.decode(encoded)
        #expect(decoded.plan == plan)
        #expect(decoded.schemaVersion == SharedPlanCodec.currentSchemaVersion)
    }

    @Test("decode rejects a newer schema version")
    func unsupportedVersion() throws {
        let future = SharedPlanPayload(
            schemaVersion: 999,
            exportedAt: exportedAt,
            plan: .previewTrainingSession
        )
        let encoded = try SharedPlanCodec.encode(future)
        #expect(throws: SharedPlanCodecError.unsupportedVersion(found: 999, supported: 1)) {
            try SharedPlanCodec.decode(encoded)
        }
    }

    @Test("decode rejects malformed input")
    func malformed() {
        #expect(throws: SharedPlanCodecError.malformed) {
            try SharedPlanCodec.decode("not-a-real-payload")
        }
    }

    @Test("fitsInQR classifies by byte budget")
    func sizeThreshold() {
        #expect(SharedPlanCodec.fitsInQR("short"))
        #expect(!SharedPlanCodec.fitsInQR(String(repeating: "a", count: 2000)))
    }
}
