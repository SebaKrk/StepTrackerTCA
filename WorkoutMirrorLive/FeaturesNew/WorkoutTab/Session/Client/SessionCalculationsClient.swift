//
//  SessionCalculationsClient.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 28/08/2025.
//

import ComposableArchitecture
import Foundation
import SharedModels

struct SessionCalculationsClient {
    
    var calculateHeartRateZone: (_ current: Int, _ max: Int) -> HeartRateZone
    var calculateHeartRatePercentage: (_ current: Int, _ max: Int) -> Int

    var processHeartRate: (_ hr: Int) async -> (average: Int, max: Int)
    var resetSession: () async -> Void
}

extension DependencyValues {
    var sessionCalculations: SessionCalculationsClient {
        get { self[SessionCalculationsClientKey.self] }
        set { self[SessionCalculationsClientKey.self] = newValue }
    }
}

private enum SessionCalculationsClientKey: DependencyKey {
    static let liveValue: SessionCalculationsClient = {
        actor SessionState {
            var heartRateSum: Int = 0
            var heartRateCount: Int = 0
            var maxHeartRate: Int = 0

            func process(_ hr: Int) -> (average: Int, max: Int) {
                heartRateSum += hr
                heartRateCount += 1
                maxHeartRate = max(maxHeartRate, hr)
                let average = heartRateCount > 0 ? heartRateSum / heartRateCount : 0
                return (average, maxHeartRate)
            }

            func reset() {
                heartRateSum = 0
                heartRateCount = 0
                maxHeartRate = 0
            }
        }

        let sessionState = SessionState()

        return SessionCalculationsClient(
            calculateHeartRateZone: { current, max in
                guard max > 0 else { return .resting }
                let percentage = Double(current) / Double(max)
                switch percentage {
                case 0..<0.5:    return .resting
                case 0.5..<0.6:  return .recovery
                case 0.6..<0.7:  return .fatBurning
                case 0.7..<0.8:  return .aerobic
                case 0.8..<0.9:  return .threshold
                case 0.9...1.0:  return .anaerobic
                default:         return .resting
                }
            },
            calculateHeartRatePercentage: { current, max in
                guard max > 0 else { return 0 }
                let percentage = Double(current) / Double(max) * 100
                return Int(percentage)
            },
            processHeartRate: { hr in
                await sessionState.process(hr)
            },
            resetSession: {
                await sessionState.reset()
            }
        )
    }()
}
