//
//  QRCodeImageClient.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 25/10/2026.
//

import ComposableArchitecture
import CoreImage
import CoreImage.CIFilterBuiltins
import Foundation

// MARK: - Client

/// Renders text into a QR image off the main thread.
struct QRCodeImageClient: Sendable {

    /// QR image for the text, or `nil` when rendering fails.
    var image: @Sendable (_ text: String) async -> CGImage?
}

// MARK: - DependencyValues

extension DependencyValues {
    var qrCodeImageClient: QRCodeImageClient {
        get { self[QRCodeImageClientKey.self] }
        set { self[QRCodeImageClientKey.self] = newValue }
    }
}

// MARK: - DependencyKey

private enum QRCodeImageClientKey: DependencyKey {

    static let liveValue = QRCodeImageClient(
        image: { text in render(text) }
    )

    static var previewValue: QRCodeImageClient {
        QRCodeImageClient(image: { text in render(text) })
    }

    static var testValue: QRCodeImageClient {
        QRCodeImageClient(image: unimplemented("QRCodeImageClient.image", placeholder: nil))
    }

    // Same rendering as the plan QR (`PlanShareClient`); a shared renderer waits for a third use.
    nonisolated private static let context = CIContext()

    nonisolated private static func render(_ text: String) -> CGImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(text.utf8)
        filter.correctionLevel = "M"
        guard let output = filter.outputImage else { return nil }
        let scaled = output.transformed(by: .init(scaleX: 10, y: 10))
        return context.createCGImage(scaled, from: scaled.extent)
    }
}
