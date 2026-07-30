//
//  WatchConnectivityStatusActor.swift
//  HealthHub
//
//  Created by Sebastian Sciuba on 17/09/2025.
//

import WatchConnectivity

/// Actor odpowiedzialny za zarządzanie statusem WatchConnectivity
@preconcurrency
actor WatchConnectivityStatusActor {
    
    init() {
        print("🟢 WatchConnectivityStatusActor init")
    }
    
    deinit {
        print("🪦 -> ❌ WatchConnectivityStatusActor deinit")
    }
    
    // MARK: - Status Properties
    
    /// Aktualny status połączenia z Watch
    var status: WatchConnectivityStatus = .unknown
    
    // MARK: - Status Methods
    
    /// Thread-safe update statusu
    func updateStatus(_ newStatus: WatchConnectivityStatus) {
        let oldStatus = status
        status = newStatus
        
        if oldStatus != newStatus {
            print("📡 WatchConnectivityStatusActor: Status changed from \(oldStatus) to \(newStatus)")
        }
    }
}
