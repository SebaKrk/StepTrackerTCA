//
//  ScanImageDownscaler.swift
//  HealthHub
//
//  Created by Sebastian Ściuba on 29/10/2026.
//

import Foundation
import ImageIO
import UniformTypeIdentifiers

/// Shrinks a scanned board to the size the model actually reads.
///
/// Claude resizes anything above ~1568 px on the long edge server-side, so sending
/// more only costs upload time; image tokens scale with pixel count.
enum ScanImageDownscaler {

    static let maxPixelSize = 1568

    static func jpeg(from data: Data, maxPixelSize: Int = maxPixelSize, quality: Double = 0.8) throws -> Data {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            throw ClaudeAPIError.invalidImage
        }
        let thumbnailOptions: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
        ]
        guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, thumbnailOptions as CFDictionary) else {
            throw ClaudeAPIError.invalidImage
        }
        let output = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(output, UTType.jpeg.identifier as CFString, 1, nil) else {
            throw ClaudeAPIError.invalidImage
        }
        let encodeOptions: [CFString: Any] = [kCGImageDestinationLossyCompressionQuality: quality]
        CGImageDestinationAddImage(destination, image, encodeOptions as CFDictionary)
        guard CGImageDestinationFinalize(destination) else {
            throw ClaudeAPIError.invalidImage
        }
        return output as Data
    }
}
