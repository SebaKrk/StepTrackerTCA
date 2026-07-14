//
//  BLECapacityClient.swift
//  PeerMirror
//
//  Created by Sebastian Ściuba on 17/06/2026.
//

import ComposableArchitecture
import Darwin
import Foundation

/// The Composable Architecture (TCA) dependency boundary nad runtime BLE capacity lookup.
///
/// **Domain**: `CBPeripheralManager` connection capacity — Apple nie publikuje explicit
/// per-device limit w docs ("subject to hardware constraints"). Klient enkapsuluje
/// community-tested defaults oparte o `hw.machine` model identifier.
///
/// **Per-device capacity** (rekomendowane default'y):
/// - iPad Pro M-series (iPad14+/15+/16+) → 16 (najszybsze BLE radio)
/// - iPad Air 5 (M1, iPad13) / iPad Pro A12X (iPad8) → 12 (middle tier)
/// - Pozostałe iPady (Air 4, mini, regular iPad 9/10) → 8 (safe default)
/// - Non-iPad / unknown → 8 (conservative fallback)
///
/// **Upper bound** dla user-facing UI to stała `16` — practical Apple cap niezależny
/// od device'a (Stepper range w Class Creation form).
///
/// **Pattern**: ten sam co `PeerMirrorClient` — `struct: Sendable` z closure properties
/// (bez `@DependencyClient` macro dla konsystencji w obrębie modułu).
///
/// **Reuse**:
/// - `ClassCreationFeature` (GymRoom) — Stepper range + recommended default
/// - Future: `PeerMirrorBLEHostSession.didReceiveWrite` — reject peer'ów gdy
///   `connectedCount >= recommendedMaxConnections` (runtime enforcement)
public struct BLECapacityClient: Sendable {

    /// Rekomendowany default dla `state.maxParticipants` w nowej klasie. Per-device,
    /// computed z `hw.machine` sysctl (low cost ~µs). Wywoływany raz w `viewDidAppear`.
    public var recommendedMaxConnections: @Sendable () -> Int

    /// Stała upper bound dla Stepper UI — practical Apple cap (16). Niezależny od device'a.
    /// User może zwiększyć ponad recommended jeśli BLE radio wytrzyma (na własną odpowiedzialność).
    public var upperBound: @Sendable () -> Int

    public init(
        recommendedMaxConnections: @escaping @Sendable () -> Int,
        upperBound: @escaping @Sendable () -> Int
    ) {
        self.recommendedMaxConnections = recommendedMaxConnections
        self.upperBound = upperBound
    }
}

// MARK: - DependencyKey

extension BLECapacityClient: DependencyKey {

    public static let liveValue: BLECapacityClient = BLECapacityClient(
        recommendedMaxConnections: {
            capacityForCurrentDevice()
        },
        upperBound: {
            16
        }
    )

    public static let previewValue: BLECapacityClient = BLECapacityClient(
        recommendedMaxConnections: { 8 },
        upperBound: { 16 }
    )

    public static let testValue: BLECapacityClient = BLECapacityClient(
        recommendedMaxConnections: unimplemented("BLECapacityClient.recommendedMaxConnections", placeholder: 8),
        upperBound: unimplemented("BLECapacityClient.upperBound", placeholder: 16)
    )

    /// Returns BLE capacity dla bieżącego device'a na podstawie `hw.machine` sysctl.
    /// Pattern-match na model identifier prefix — jednorazowy lookup, low cost.
    private static func capacityForCurrentDevice() -> Int {
        let model = deviceModelIdentifier()

        // iPad Pro M-series (M1/M2/M4) — najszybsze BLE radio
        if model.hasPrefix("iPad14") || model.hasPrefix("iPad15") || model.hasPrefix("iPad16") {
            return 16
        }

        // iPad Air 5 (M1, iPad13) / iPad Pro A12X (iPad8) — middle tier
        if model.hasPrefix("iPad13") || model.hasPrefix("iPad8") {
            return 12
        }

        // Pozostałe iPady (Air 4, mini, regular iPad 9/10)
        if model.hasPrefix("iPad") {
            return 8
        }

        // Non-iPad (Mac Catalyst, simulator) — conservative fallback
        return 8
    }

    /// `sysctlbyname("hw.machine")` — returns device model identifier (np. `"iPad14,3"`).
    private static func deviceModelIdentifier() -> String {
        var size: Int = 0
        sysctlbyname("hw.machine", nil, &size, nil, 0)
        var machine = [CChar](repeating: 0, count: size)
        sysctlbyname("hw.machine", &machine, &size, nil, 0)
        return String(cString: machine)
    }
}

// MARK: - DependencyValues

public extension DependencyValues {
    var bleCapacityClient: BLECapacityClient {
        get { self[BLECapacityClient.self] }
        set { self[BLECapacityClient.self] = newValue }
    }
}
