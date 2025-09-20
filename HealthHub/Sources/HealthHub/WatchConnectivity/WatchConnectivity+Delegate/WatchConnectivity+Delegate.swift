//
//  WatchConnectivity+Delegate.swift
//  HealthHub
//
//  Created by Sebastian Sciuba on 17/09/2025.
//

import WatchConnectivity

extension DefaultWatchConnectivityManager: WCSessionDelegate {
    
    /// Wywoływane gdy sesja WatchConnectivity się aktywuje
    public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("🔄 WCSession activation completed with state: \(activationState.rawValue)")
        
        Task {
            if let error = error {
                print("❌ WCSession activation error: \(error.localizedDescription)")
                await statusActor.updateStatus(.unknown)
                return
            }
            
            switch activationState {
            case .activated:
                print("✅ WCSession activated successfully")
                let status = await checkConnectionStatus()
                print("📊 Final status: \(status)")
                
            case .inactive:
                print("⚠️ WCSession inactive")
                await statusActor.updateStatus(.unknown)
                
            case .notActivated:
                print("❌ WCSession not activated")
                await statusActor.updateStatus(.unknown)
                
            @unknown default:
                print("❓ Unknown WCSession activation state")
                await statusActor.updateStatus(.unknown)
            }
        }
    }
    
    /// Wywoływane gdy sesja staje się nieaktywna
    public func sessionDidBecomeInactive(_ session: WCSession) {
        print("📴 WCSession became inactive")
        Task {
            await statusActor.updateStatus(.unknown)
        }
    }
    
    /// Wywoływane gdy sesja się deaktywuje
    public func sessionDidDeactivate(_ session: WCSession) {
        print("🔄 WCSession deactivated - reactivating...")
        Task {
            await statusActor.updateStatus(.unknown)
        }
        
        // Apple zaleca ponowną aktywację
        session.activate()
    }
    
    /// Wywoływane gdy zmienia się dostępność Watch
    public func sessionReachabilityDidChange(_ session: WCSession) {
        print("🔄 Watch reachability changed: \(session.isReachable)")
        Task {
            let status = await checkConnectionStatus()
            print("📊 New status after reachability change: \(status)")
        }
    }
}
