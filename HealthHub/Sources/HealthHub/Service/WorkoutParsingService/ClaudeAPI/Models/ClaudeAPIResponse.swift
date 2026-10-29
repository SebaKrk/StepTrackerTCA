//
//  ClaudeAPIResponse.swift
//  HealthHub
//
//  Created by Sebastian Sciuba on 15/02/2026.
//

import Foundation

/// Response from Claude API.
public struct ClaudeAPIResponse: Decodable, Sendable {

    /// Blocks of the reply in order.
    public let content: [ContentBlock]

    /// Why the model stopped: `end_turn`, `max_tokens`, `refusal`, …
    public let stopReason: String?

    /// Token accounting of the call; nil on old responses.
    public let usage: Usage?

    enum CodingKeys: String, CodingKey {
        case content
        case stopReason = "stop_reason"
        case usage
    }

    /// First text block; thinking and unknown blocks are skipped.
    public var firstText: String? {
        for block in content {
            if case .text(let text) = block { return text }
        }
        return nil
    }

    /// `max_tokens` means the JSON was cut off; `refusal` means it may not match the schema.
    public var isTruncated: Bool { stopReason == "max_tokens" }
    public var isRefusal: Bool { stopReason == "refusal" }

    /// Content blocks the API can return; new block kinds decode as `.other`
    /// instead of failing the whole response.
    public enum ContentBlock: Decodable, Sendable {

        /// A text block with its content.
        case text(String)

        /// A thinking block; its content is not read.
        case thinking

        /// A thinking block the API redacted.
        case redactedThinking

        /// A block kind this client does not know, with its `type`.
        case other(String)

        enum CodingKeys: String, CodingKey {
            case type
            case text
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let type = try container.decode(String.self, forKey: .type)
            switch type {
            case "text":
                self = .text(try container.decode(String.self, forKey: .text))
            case "thinking":
                self = .thinking
            case "redacted_thinking":
                self = .redactedThinking
            default:
                self = .other(type)
            }
        }
    }

    /// Token accounting of one call.
    public struct Usage: Decodable, Sendable {

        /// Input tokens billed at full price.
        public let inputTokens: Int

        /// Output tokens, thinking included.
        public let outputTokens: Int

        /// Tokens written to the prompt cache.
        public let cacheCreationInputTokens: Int?

        /// Tokens read from the prompt cache.
        public let cacheReadInputTokens: Int?

        enum CodingKeys: String, CodingKey {
            case inputTokens = "input_tokens"
            case outputTokens = "output_tokens"
            case cacheCreationInputTokens = "cache_creation_input_tokens"
            case cacheReadInputTokens = "cache_read_input_tokens"
        }
    }
}
