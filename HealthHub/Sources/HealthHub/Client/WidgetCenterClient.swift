//
//  WidgetCenterClient.swift
//  HealthHub
//
//  Created by Sebastian Sciuba on 25/01/2026.
//

import ComposableArchitecture
import Foundation
import WidgetKit

/// Client for interacting with WidgetCenter functionality.
public struct WidgetCenterClient: Sendable {
    public var reloadTimelines: @Sendable (String) -> Void
    public var reloadAllTimelines: @Sendable () -> Void
    
    public init(
        reloadTimelines: @escaping @Sendable (String) -> Void,
        reloadAllTimelines: @escaping @Sendable () -> Void
    ) {
        self.reloadTimelines = reloadTimelines
        self.reloadAllTimelines = reloadAllTimelines
    }
}

// MARK: - DependencyKey

extension WidgetCenterClient: DependencyKey {
    public static let liveValue: WidgetCenterClient = WidgetCenterClient(
        reloadTimelines: { kind in
            WidgetCenter.shared.reloadTimelines(ofKind: kind)
        },
        reloadAllTimelines: {
            WidgetCenter.shared.reloadAllTimelines()
        }
    )
    
    public static let testValue: WidgetCenterClient = WidgetCenterClient(
        reloadTimelines: { _ in },
        reloadAllTimelines: { }
    )
}

// MARK: - DependencyValues

public extension DependencyValues {
    var widgetCenterClient: WidgetCenterClient {
        get { self[WidgetCenterClient.self] }
        set { self[WidgetCenterClient.self] = newValue }
    }
}
