//
//  JSONValue.swift
//  HealthHub
//
//  Created by Sebastian Ściuba on 29/10/2026.
//

import Foundation

/// A JSON document expressed as a Swift value, written with plain literals.
///
/// Used for request fragments that have no fixed shape, such as the JSON schema
/// handed to Claude's structured outputs.
public indirect enum JSONValue: Encodable, Sendable, Equatable {

    /// A JSON string.
    case string(String)

    /// A JSON number without a fraction.
    case integer(Int)

    /// A JSON number with a fraction.
    case number(Double)

    /// `true` / `false`.
    case bool(Bool)

    /// `null`.
    case null

    /// An ordered list of values.
    case array([JSONValue])

    /// A dictionary of members; key order is not preserved.
    case object([String: JSONValue])

    public func encode(to encoder: Encoder) throws {
        switch self {
        case .string(let value):
            var container = encoder.singleValueContainer()
            try container.encode(value)
        case .integer(let value):
            var container = encoder.singleValueContainer()
            try container.encode(value)
        case .number(let value):
            var container = encoder.singleValueContainer()
            try container.encode(value)
        case .bool(let value):
            var container = encoder.singleValueContainer()
            try container.encode(value)
        case .null:
            var container = encoder.singleValueContainer()
            try container.encodeNil()
        case .array(let values):
            var container = encoder.unkeyedContainer()
            for value in values {
                try container.encode(value)
            }
        case .object(let members):
            var container = encoder.container(keyedBy: ObjectKey.self)
            for (name, value) in members {
                try container.encode(value, forKey: ObjectKey(name))
            }
        }
    }

    private struct ObjectKey: CodingKey {
        let stringValue: String
        var intValue: Int? { nil }

        init(_ name: String) { stringValue = name }
        init?(stringValue: String) { self.stringValue = stringValue }
        init?(intValue: Int) { nil }
    }
}

// MARK: - Literals

extension JSONValue: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) { self = .string(value) }
}

extension JSONValue: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) { self = .integer(value) }
}

extension JSONValue: ExpressibleByFloatLiteral {
    public init(floatLiteral value: Double) { self = .number(value) }
}

extension JSONValue: ExpressibleByBooleanLiteral {
    public init(booleanLiteral value: Bool) { self = .bool(value) }
}

extension JSONValue: ExpressibleByNilLiteral {
    public init(nilLiteral: ()) { self = .null }
}

extension JSONValue: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: JSONValue...) { self = .array(elements) }
}

extension JSONValue: ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral elements: (String, JSONValue)...) {
        self = .object(Dictionary(elements, uniquingKeysWith: { _, last in last }))
    }
}
