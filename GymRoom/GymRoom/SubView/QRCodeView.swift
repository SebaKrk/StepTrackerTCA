//
//  QRCodeView.swift
//  GymRoom
//
//  Created by Sebastian Ściuba on 11/06/2026.
//

import CoreImage.CIFilterBuiltins
import SwiftUI

/// QR code generator dla `QRSessionPayload` (JSON encoded).
///
/// **`.interpolation(.none)` jest wymagane** — bez tego SwiftUI scaling antyaliasinguje
/// piksele QR'a → scanner nie potrafi rozpoznać. To wymusza nearest-neighbor scaling
/// zachowujący ostre piksele przy resize.
///
/// **`CIContext` jako `static let`** — drogi w tworzeniu (~10-30ms init).
/// Sharing jednej instancji między wszystkimi `QRCodeView` daje ~zero overhead per render.
struct QRCodeView: View {

    /// JSON-encoded `QRSessionPayload` (UTF-8 string).
    let payload: String

    /// Shared CIContext — drogi w tworzeniu, OK żeby był static dla wszystkich instancji.
    private static let context = CIContext()

    // MARK: - Body

    var body: some View {
        if let cgImage = generate() {
            Image(decorative: cgImage, scale: 1.0)
                .interpolation(.none)
                .resizable()
                .scaledToFit()
        } else {
            // Fallback gdy generation fails (rzadkie — zwykle payload zbyt długi
            // dla CIQRCodeGenerator). User widzi ikonę QR jako placeholder.
            fallbackPlaceholder
        }
    }

    // MARK: - Private

    private var fallbackPlaceholder: some View {
        ZStack {
            Color.gray.opacity(0.3)
            Image(systemName: "qrcode")
                .resizable()
                .scaledToFit()
                .padding(20)
                .foregroundStyle(.white.opacity(0.6))
        }
    }

    private func generate() -> CGImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(payload.utf8)
        filter.correctionLevel = "M"  // Medium (15% redundancy) — wystarczy dla iPad screen

        guard let output = filter.outputImage else { return nil }
        // Native QR ~25×25px — scale up żeby było widoczne na iPadzie.
        // Affine transform + .interpolation(.none) → ostre piksele, scanner czyta.
        let scaled = output.transformed(by: .init(scaleX: 10, y: 10))
        return Self.context.createCGImage(scaled, from: scaled.extent)
    }
}

// MARK: - Previews

#Preview("Sample payload") {
    QRCodeView(
        payload: #"{"token":"550E8400-E29B-41D4-A716-446655440000","iPadID":"123E4567-E89B-12D3-A456-426614174000","gymName":"Iron Den","createdAt":"2026-06-11T12:00:00Z"}"#
    )
    .frame(width: 200, height: 200)
    .padding()
    .background(.black)
}

#Preview("Short payload") {
    QRCodeView(payload: "test-payload-123")
        .frame(width: 200, height: 200)
        .padding()
        .background(.black)
}
