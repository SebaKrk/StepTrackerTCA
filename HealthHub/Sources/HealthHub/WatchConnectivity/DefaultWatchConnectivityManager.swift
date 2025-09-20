//
//  DefaultWatchConnectivityManager.swift
//  HealthHub
//
//  Created by Sebastian Sciuba on 17/09/2025.
//

import WatchConnectivity

@preconcurrency
public final class DefaultWatchConnectivityManager: NSObject, WatchConnectivityManager, @unchecked Sendable {
    
    /// WCSession z WatchConnectivity
    private var session: WCSession?
    
    /// Actor zarządzający statusem
    let statusActor = WatchConnectivityStatusActor()
    
    override init() {
        super.init()
        print("🍎 🟢 Created DefaultWatchConnectivityManager")
    }
    
    deinit {
        print("🪦 -> ❌ DefaultWatchConnectivityManager deinit")
    }
    
    // MARK: - WatchConnectivityManager Protocol Implementation
    
    /// Czy WatchConnectivity jest obsługiwane na tym urządzeniu
    public var isSupported: Bool {
        get async {
            return WCSession.isSupported()
        }
    }
    
    /// Czy Apple Watch jest sparowany
    public var isPaired: Bool {
        get async {
            guard let session = session else { return false }
            return session.isPaired
        }
    }
    
    /// Czy aplikacja Watch jest zainstalowana
    public var isWatchAppInstalled: Bool {
        get async {
            guard let session = session else { return false }
            return session.isWatchAppInstalled
        }
    }
    
    /// Czy można komunikować się z Watch
    public var isReachable: Bool {
        get async {
            guard let session = session else { return false }
            return session.isReachable
        }
    }
    
    /// Aktualny status połączenia
    public var currentStatus: WatchConnectivityStatus {
        get async {
            return await statusActor.status
        }
    }
    
    /// Inicjalizuje WatchConnectivity session
    public func initializeWatchConnectivity() async {
        print("🍎 DefaultWatchConnectivityManager: initializeWatchConnectivity() called")
        
        guard WCSession.isSupported() else {
            print("❌ WatchConnectivity not supported")
            await statusActor.updateStatus(.notSupported)
            return
        }
        
        session = WCSession.default
        session?.delegate = self
        session?.activate()
        
        print("🔄 WCSession activation started...")
    }
    
    /// Sprawdza pełny status połączenia
    public func checkConnectionStatus() async -> WatchConnectivityStatus {
        guard WCSession.isSupported() else {
            await statusActor.updateStatus(.notSupported)
            return .notSupported
        }
        
        guard let session = session else {
            await statusActor.updateStatus(.unknown)
            return .unknown
        }
        
        if session.isPaired {
            await statusActor.updateStatus(.ready)
            return .ready
        } else {
            await statusActor.updateStatus(.notPaired)
            return .notPaired
        }
        
//        // Sprawdź w kolejności ważności
//        if !session.isPaired {
//            await statusActor.updateStatus(.notPaired)
//            return .notPaired
//        }
//        
//        if !session.isWatchAppInstalled {
//            await statusActor.updateStatus(.appNotInstalled)
//            return .appNotInstalled
//        }
//        
//        if session.isReachable {
//            await statusActor.updateStatus(.ready)
//            return .ready
//        } else {
//            await statusActor.updateStatus(.unreachable)
//            return .unreachable
//        }
    }
    
    public func stopWatchConnectivity() async {
        print("🛑 Stopping WatchConnectivity...")
        session?.delegate = nil
        session = nil
        await statusActor.updateStatus(.unknown)
    }
    
}
