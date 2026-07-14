//
//  HTTPClient.swift
//  HealthHub
//
//  Created by Sebastian Sciuba on 15/02/2026.
//

import Foundation

/// Generic HTTP client for making network requests.
public protocol HTTPClient: Sendable {
    /// Sends a request and decodes the response.
    func send<Request: Encodable & Sendable, Response: Decodable & Sendable>(
        request: Request,
        to endpoint: URL,
        method: String,
        headers: [String: String]
    ) async throws -> Response
}

/// URLSession-based implementation of HTTPClient.
public actor URLSessionHTTPClient: HTTPClient {

    private let session: URLSession
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init(
        session: URLSession = .shared,
        encoder: JSONEncoder = JSONEncoder(),
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.session = session
        self.encoder = encoder
        self.decoder = decoder
    }

    public func send<Request: Encodable & Sendable, Response: Decodable & Sendable>(
        request: Request,
        to endpoint: URL,
        method: String = "POST",
        headers: [String: String] = [:]
    ) async throws -> Response {
        var urlRequest = URLRequest(url: endpoint)
        urlRequest.httpMethod = method

        // Set headers
        headers.forEach { key, value in
            urlRequest.setValue(value, forHTTPHeaderField: key)
        }

        // Encode body
        urlRequest.httpBody = try encoder.encode(request)

        // Send request
        let (data, response) = try await session.data(for: urlRequest)

        // Validate HTTP response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw HTTPError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw HTTPError.httpError(statusCode: httpResponse.statusCode)
        }

        // Decode response
        return try decoder.decode(Response.self, from: data)
    }
}

/// HTTP-related errors.
public enum HTTPError: Error, LocalizedError {
    case invalidResponse
    case httpError(statusCode: Int)

    public var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid HTTP response"
        case .httpError(let statusCode):
            return "HTTP error: \(statusCode)"
        }
    }
}
