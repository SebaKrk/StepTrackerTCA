//
//  ClaudeAPIRequest.swift
//  HealthHub
//
//  Created by Sebastian Sciuba on 15/02/2026.
//

import Foundation

/// Request to Claude API.
public struct ClaudeAPIRequest: Encodable, Sendable {
    public let model: String
    public let maxTokens: Int
    public let system: [SystemBlock]
    public let messages: [Message]
    public let thinking: Thinking?
    public let outputConfig: OutputConfig?

    enum CodingKeys: String, CodingKey {
        case model
        case maxTokens = "max_tokens"
        case system
        case messages
        case thinking
        case outputConfig = "output_config"
    }

    /// One block of the system prompt; the last cached block is the cache breakpoint.
    public struct SystemBlock: Encodable, Sendable {
        public let type = "text"
        public let text: String
        public let cacheControl: CacheControl?

        enum CodingKeys: String, CodingKey {
            case type
            case text
            case cacheControl = "cache_control"
        }

        public init(text: String, cached: Bool) {
            self.text = text
            self.cacheControl = cached ? CacheControl() : nil
        }
    }

    public struct CacheControl: Encodable, Sendable {
        public let type = "ephemeral"
    }

    public struct Message: Encodable, Sendable {
        public let role: String
        public let content: String

        public init(role: String, content: String) {
            self.role = role
            self.content = content
        }
    }

    /// Extended-thinking mode; `between_tools` is the "off" Sonnet 5.5 accepts.
    public struct Thinking: Encodable, Sendable {
        public let type: String
    }

    public struct OutputConfig: Encodable, Sendable {
        public let effort: String?
        public let format: Format?

        public struct Format: Encodable, Sendable {
            public let type = "json_schema"
            public let schema: JSONValue
        }
    }

    public init(
        model: String,
        maxTokens: Int,
        system: String,
        messages: [Message],
        options: ClaudeRequestOptions = ClaudeRequestOptions()
    ) {
        self.model = model
        self.maxTokens = maxTokens
        self.system = [SystemBlock(text: system, cached: options.cachesSystemPrompt)]
        self.messages = messages
        self.thinking = options.disablesThinking ? Thinking(type: "between_tools") : nil
        let format = options.outputSchema.map { OutputConfig.Format(schema: $0) }
        self.outputConfig = (options.effort == nil && format == nil)
            ? nil
            : OutputConfig(effort: options.effort?.rawValue, format: format)
    }
}
