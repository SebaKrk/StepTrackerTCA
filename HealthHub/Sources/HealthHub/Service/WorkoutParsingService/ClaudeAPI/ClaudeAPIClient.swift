//
//  ClaudeAPIClient.swift
//  HealthHub
//
//  Created by Sebastian Sciuba on 15/02/2026.
//

import Foundation

/// Client for communicating with Claude API.
public actor ClaudeAPIClient {

    // MARK: - Constants

    private static let endpoint = URL(string: "https://api.anthropic.com/v1/messages")!
    private static let apiVersion = "2023-06-01"

    // MARK: - Properties

    private let httpClient: HTTPClient
    private let apiKey: String

    // MARK: - Initialization

    public init(
        httpClient: HTTPClient,
        apiKey: String? = nil
    ) {
        self.httpClient = httpClient
        self.apiKey = apiKey ?? ""
    }

    // MARK: - Public Methods

    /// Sends a message to Claude API.
    public func sendMessage(
        model: String,
        system: String,
        userMessage: String,
        maxTokens: Int = 4096
    ) async throws -> ClaudeAPIResponse {
        guard !apiKey.isEmpty else {
            throw ClaudeAPIError.missingAPIKey
        }

        let request = ClaudeAPIRequest(
            model: model,
            maxTokens: maxTokens,
            system: system,
            messages: [.init(role: "user", content: userMessage)]
        )

        let headers = [
            "Content-Type": "application/json",
            "x-api-key": apiKey,
            "anthropic-version": Self.apiVersion
        ]

        return try await httpClient.send(
            request: request,
            to: Self.endpoint,
            method: "POST",
            headers: headers
        )
    }
}
