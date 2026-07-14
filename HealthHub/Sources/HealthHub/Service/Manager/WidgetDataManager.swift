//
//  WidgetDataManager.swift
//  HealthHub
//
//  Created by Sebastian Sciuba on 24/01/2026.
//

import Foundation
import SharedModels

/// Manager for widget-specific data storage.
/// Uses App Group UserDefaults for Widget <-> Main App communication.
public final class WidgetDataManager: @unchecked Sendable {
    
    private let storage: UserDefaultsServiceManager
    private let key = "widget_readiness_data"
    
    public init() {
        self.storage = .appGroup
    }
    
    /// Saves widget readiness data.
    public func save(_ data: WidgetReadinessData) {
        storage.save(data, forKey: key)
    }
    
    /// Loads widget readiness data.
    public func load() -> WidgetReadinessData? {
        storage.load(forKey: key)
    }
    /// Requires removing widget readiness data.
    public func clear() {
        storage.remove(forKey: key)
    }
}

