//
//  ScanProxy.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 17/11/2026.
//

import ComposableArchitecture
import FirebaseAuth
import FirebaseCore
import Foundation
import HealthHub

/// The app's single transport to the server-side scan proxy.
///
/// `HealthHub` knows nothing about Firebase, so the project id and the identity
/// token are supplied from here. The project comes from the configured app, which
/// is why the dev and release builds reach their own functions with no switch.
enum ScanProxy {

    /// Region the functions are deployed to.
    nonisolated private static let region = "europe-central2"

    /// One client per process; it holds nothing beyond its configuration.
    ///
    /// `nonisolated` throughout: the clients that reach for it are themselves
    /// nonisolated `liveValue`s, and the target defaults to `MainActor`.
    nonisolated static let shared = ScanProxyClient(
        configuration: ScanProxyConfiguration(
            region: region,
            projectID: { FirebaseApp.app()?.options.projectID },
            idToken: { try await identityToken() }
        )
    )

    /// Identity token of the current account, creating one if onboarding never did.
    ///
    /// Onboarding writes `accountUid` and `AppTabNewFeature` backfills it at launch,
    /// so this normally returns the token of an account that already exists.
    nonisolated private static func identityToken() async throws -> String {
        @Dependency(\.teamClient) var teamClient
        _ = try await teamClient.ensureSignedIn()
        guard let user = Auth.auth().currentUser else {
            throw ScanProxyError.notSignedIn
        }
        return try await user.getIDToken()
    }
}
