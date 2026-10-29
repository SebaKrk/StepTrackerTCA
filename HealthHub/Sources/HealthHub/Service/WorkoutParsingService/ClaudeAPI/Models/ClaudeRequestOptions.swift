//
//  ClaudeRequestOptions.swift
//  HealthHub
//
//  Created by Sebastian Ściuba on 29/10/2026.
//

import Foundation

/// Per-call knobs of a Claude request that are not part of the prompt itself.
public struct ClaudeRequestOptions: Sendable {

    /// Reasoning budget; `nil` leaves the model's default.
    public enum Effort: String, Sendable {
        case low
        case medium
        case high
    }

    /// Marks the system prompt as a cache breakpoint. Only worth it above the
    /// model's minimum cacheable prefix (512 tokens on Sonnet 5.5).
    public var cachesSystemPrompt: Bool

    /// Turns extended thinking off. Sonnet 5.5 rejects `disabled`, so this is
    /// sent as `between_tools`, the lowest setting that model accepts.
    public var disablesThinking: Bool

    /// Reasoning effort sent in `output_config.effort`.
    public var effort: Effort?

    /// JSON schema the response must satisfy (structured outputs); `nil` = free text.
    public var outputSchema: JSONValue?

    public init(
        cachesSystemPrompt: Bool = false,
        disablesThinking: Bool = false,
        effort: Effort? = nil,
        outputSchema: JSONValue? = nil
    ) {
        self.cachesSystemPrompt = cachesSystemPrompt
        self.disablesThinking = disablesThinking
        self.effort = effort
        self.outputSchema = outputSchema
    }
}
