//
//  ScanProxyConfiguration.swift
//  HealthHub
//
//  Created by Sebastian Ściuba on 17/11/2026.
//

import Foundation

/// Where the scan proxy lives and how a request proves who is asking.
///
/// The package stays free of Firebase: the app layer supplies the project id and
/// the identity token, so this type knows only how to turn them into a URL and a
/// header.
public struct ScanProxyConfiguration: Sendable {

    /// Region the functions are deployed to, e.g. `europe-central2`.
    public let region: String

    /// Firebase project of the running build; `nil` before Firebase is configured.
    public let projectID: @Sendable () -> String?

    /// Identity token of the signed-in account, refreshed on each call.
    public let idToken: @Sendable () async throws -> String

    public init(
        region: String,
        projectID: @escaping @Sendable () -> String?,
        idToken: @escaping @Sendable () async throws -> String
    ) {
        self.region = region
        self.projectID = projectID
        self.idToken = idToken
    }

    /// Callable endpoint of one function by name.
    func endpoint(for function: String) throws -> URL {
        guard let projectID = projectID() else {
            throw ScanProxyError.notConfigured
        }
        guard let url = URL(string: "https://\(region)-\(projectID).cloudfunctions.net/\(function)") else {
            throw ScanProxyError.notConfigured
        }
        return url
    }
}
