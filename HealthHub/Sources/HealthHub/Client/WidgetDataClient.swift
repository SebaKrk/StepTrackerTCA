//
//  WidgetDataClient.swift
//  HealthHub
//
//  Created by Sebastian Sciuba on 24/01/2026.
//

import ComposableArchitecture
import Foundation
import SharedModels

/// TCA Dependency client for widget data storage.
public struct WidgetDataClient: Sendable {
    public var save: @Sendable (WidgetReadinessData) async -> Void
    public var saveReadinessResult: @Sendable (TrainingReadinessResult) async -> Void
    public var load: @Sendable () async -> WidgetReadinessData?
    public var clear: @Sendable () async -> Void
    
    public init(
        save: @escaping @Sendable (WidgetReadinessData) async -> Void,
        saveReadinessResult: @escaping @Sendable (TrainingReadinessResult) async -> Void,
        load: @escaping @Sendable () async -> WidgetReadinessData?,
        clear: @escaping @Sendable () async -> Void
    ) {
        self.save = save
        self.saveReadinessResult = saveReadinessResult
        self.load = load
        self.clear = clear
    }
}

// MARK: - DependencyKey

// MARK: - DependencyKey

extension WidgetDataClient: DependencyKey {
    
    public static let liveValue: WidgetDataClient = {
        
        let manager = WidgetDataManager()
        let widgetCenter = WidgetCenterClient.liveValue
        
        return WidgetDataClient(
            save: { data in
                manager.save(data)
                widgetCenter.reloadTimelines("TrainingReadinessWidget")
            },
            saveReadinessResult: { result in
                let widgetData = WidgetReadinessData(
                    overallScore: result.overallScore,
                    readinessLevelRaw: result.readinessLevel.title,
                    rhrValue: result.components.restingHeartRate?.currentValue,
                    hrvValue: result.components.heartRateVariability?.currentValue,
                    sleepValue: result.components.sleepQuality?.currentValue,
                    activityValue: result.components.previousDayLoad?.currentValue,
                    calculatedAt: result.calculatedAt
                )
                manager.save(widgetData)
                widgetCenter.reloadTimelines("TrainingReadinessWidget")
            },
            load: {
                manager.load()
            },
            clear: {
                manager.clear()
                widgetCenter.reloadTimelines("TrainingReadinessWidget")
            }
        )
    }()
}

// MARK: - DependencyValues

public extension DependencyValues {
    var widgetDataClient: WidgetDataClient {
        get { self[WidgetDataClient.self] }
        set { self[WidgetDataClient.self] = newValue }
    }
}

