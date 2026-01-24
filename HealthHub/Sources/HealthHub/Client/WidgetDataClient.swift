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
    public var load: @Sendable () async -> WidgetReadinessData?
    
    public init(
        save: @escaping @Sendable (WidgetReadinessData) async -> Void,
        load: @escaping @Sendable () async -> WidgetReadinessData?
    ) {
        self.save = save
        self.load = load
    }
}

// MARK: - DependencyKey

extension WidgetDataClient: DependencyKey {
    public static let liveValue: WidgetDataClient = {
        let manager = WidgetDataManager()
        return WidgetDataClient(
            save: { data in
                manager.save(data)
            },
            load: {
                manager.load()
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
