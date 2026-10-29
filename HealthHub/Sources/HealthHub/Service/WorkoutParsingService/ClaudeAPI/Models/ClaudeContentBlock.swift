//
//  ClaudeContentBlock.swift
//  HealthHub
//
//  Created by Sebastian Ściuba on 29/10/2026.
//

import Foundation

/// One block of a user message: text, or an inline base64 image.
public enum ClaudeContentBlock: Encodable, Sendable {

    case text(String)
    case image(Data, mediaType: String)

    enum CodingKeys: String, CodingKey {
        case type
        case text
        case source
    }

    enum SourceKeys: String, CodingKey {
        case type
        case mediaType = "media_type"
        case data
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .text(let text):
            try container.encode("text", forKey: .type)
            try container.encode(text, forKey: .text)
        case .image(let data, let mediaType):
            try container.encode("image", forKey: .type)
            var source = container.nestedContainer(keyedBy: SourceKeys.self, forKey: .source)
            try source.encode("base64", forKey: .type)
            try source.encode(mediaType, forKey: .mediaType)
            try source.encode(data.base64EncodedString(), forKey: .data)
        }
    }
}
