//
//  ClaudeAPIRequest.swift
//  HealthHub
//
//  Created by Sebastian Sciuba on 15/02/2026.
//

import Foundation

/// Request to Claude API.
public struct ClaudeAPIRequest: Encodable, Sendable {

    /// Model id, e.g. `claude-sonnet-5-5`.
    public let model: String

    /// Upper bound of output tokens, thinking included.
    public let maxTokens: Int

    /// System prompt as blocks; the last cached block is the cache breakpoint.
    public let system: [SystemBlock]

    /// Conversation turns; one user turn for a scan.
    public let messages: [Message]

    /// Extended-thinking mode; nil leaves the model's default.
    public let thinking: Thinking?

    /// Effort and structured-output format; nil when neither is set.
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

        /// Block kind; always `text`.
        public let type = "text"

        /// Prompt text of the block.
        public let text: String

        /// Present on the block that ends the cached prefix.
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

    /// Marks a cache breakpoint; `ephemeral` is the only kind the API has.
    public struct CacheControl: Encodable, Sendable {

        /// Cache kind; always `ephemeral`.
        public let type = "ephemeral"
    }

    /// One conversation turn.
    public struct Message: Encodable, Sendable {

        /// `user` or `assistant`.
        public let role: String

        /// Text and image blocks of the turn.
        public let content: [ClaudeContentBlock]

        public init(role: String, content: String) {
            self.role = role
            self.content = [.text(content)]
        }

        public init(role: String, blocks: [ClaudeContentBlock]) {
            self.role = role
            self.content = blocks
        }
    }

    /// Extended-thinking mode; `between_tools` is the "off" Sonnet 5.5 accepts.
    public struct Thinking: Encodable, Sendable {

        /// `between_tools`, `adaptive` or `enabled`.
        public let type: String
    }

    /// `output_config` of the request.
    public struct OutputConfig: Encodable, Sendable {

        /// Reasoning effort: `low`, `medium`, `high`; nil leaves the default.
        public let effort: String?

        /// Structured-output format; nil for free text.
        public let format: Format?

        /// A JSON schema the response must satisfy.
        public struct Format: Encodable, Sendable {

            /// Format kind; always `json_schema`.
            public let type = "json_schema"

            /// The schema itself.
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
