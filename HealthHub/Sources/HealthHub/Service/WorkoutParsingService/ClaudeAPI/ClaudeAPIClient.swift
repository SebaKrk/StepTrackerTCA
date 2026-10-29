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

    /// Client over `URLSession` with deterministic request bytes.
    ///
    /// Sorted keys keep the request identical between calls — the prompt cache
    /// prefix is matched byte by byte, and dictionary order is not stable.
    public static func standard(apiKey: String?) -> ClaudeAPIClient {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        return ClaudeAPIClient(httpClient: URLSessionHTTPClient(encoder: encoder), apiKey: apiKey)
    }

    // MARK: - Public Methods

    /// Sends a text-only user message to Claude API.
    public func sendMessage(
        model: String,
        system: String,
        userMessage: String,
        maxTokens: Int = 4096,
        options: ClaudeRequestOptions = ClaudeRequestOptions()
    ) async throws -> ClaudeAPIResponse {
        try await sendMessage(
            model: model,
            system: system,
            content: [.text(userMessage)],
            maxTokens: maxTokens,
            options: options
        )
    }

    /// Sends a user message made of text and image blocks to Claude API.
    public func sendMessage(
        model: String,
        system: String,
        content: [ClaudeContentBlock],
        maxTokens: Int = 4096,
        options: ClaudeRequestOptions = ClaudeRequestOptions()
    ) async throws -> ClaudeAPIResponse {
        guard !apiKey.isEmpty else {
            throw ClaudeAPIError.missingAPIKey
        }

        let request = ClaudeAPIRequest(
            model: model,
            maxTokens: maxTokens,
            system: system,
            messages: [.init(role: "user", blocks: content)],
            options: options
        )

        let headers = [
            "Content-Type": "application/json",
            "x-api-key": apiKey,
            "anthropic-version": Self.apiVersion
        ]

        do {
            let response: ClaudeAPIResponse = try await httpClient.send(
                request: request,
                to: Self.endpoint,
                method: "POST",
                headers: headers
            )
            #if DEBUG
            logUsage(of: response, model: model)
            #endif
            return response
        } catch let error as HTTPError {
            throw Self.mapped(error)
        } catch is URLError {
            throw ClaudeAPIError.network
        }
    }

    // MARK: - Private

    #if DEBUG
    /// Cache hits and stop reason at a glance — the only way to see on-device
    /// whether the system prompt actually caches.
    private func logUsage(of response: ClaudeAPIResponse, model: String) {
        let usage = response.usage
        print("""
        🧾 [ClaudeAPIClient] \(model) stop=\(response.stopReason ?? "-") \
        in=\(usage?.inputTokens ?? 0) out=\(usage?.outputTokens ?? 0) \
        cacheWrite=\(usage?.cacheCreationInputTokens ?? 0) cacheRead=\(usage?.cacheReadInputTokens ?? 0)
        """)
    }
    #endif

    /// Maps transport-level failures to typed API errors so callers can
    /// distinguish a bad key from a rate limit or an outage.
    private static func mapped(_ error: HTTPError) -> ClaudeAPIError {
        switch error {
        case .invalidResponse:
            return .invalidResponse
        case .httpError(let statusCode):
            switch statusCode {
            case 401, 403:
                return .unauthorized
            case 429:
                return .rateLimited
            case 500...599:
                return .serverError(statusCode: statusCode)
            default:
                return .httpError(statusCode: statusCode)
            }
        }
    }
}
