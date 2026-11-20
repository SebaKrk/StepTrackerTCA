//
//  PhotoCropper.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 29/10/2026.
//

import UIKit

/// Cuts a unit-space rectangle out of a photo and re-encodes it as JPEG.
///
/// Draws through `UIImage` so the EXIF orientation is applied before cropping —
/// a crop rectangle chosen on screen matches what the user saw.
enum PhotoCropper {

    /// Nil when the data is not an image; the caller falls back to the original.
    nonisolated static func jpeg(from data: Data, unitRect: CGRect) -> Data? {
        guard let image = UIImage(data: data) else { return nil }
        let size = image.size
        let cropRect = CGRect(
            x: (unitRect.minX * size.width).rounded(.down),
            y: (unitRect.minY * size.height).rounded(.down),
            width: max(1, (unitRect.width * size.width).rounded()),
            height: max(1, (unitRect.height * size.height).rounded())
        )
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: cropRect.size, format: format)
        return renderer.jpegData(withCompressionQuality: 0.8) { _ in
            image.draw(at: CGPoint(x: -cropRect.minX, y: -cropRect.minY))
        }
    }
}
