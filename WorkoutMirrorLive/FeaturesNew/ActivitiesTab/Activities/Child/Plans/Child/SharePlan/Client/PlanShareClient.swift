//
//  PlanShareClient.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 13/07/2026.
//

import CoreImage.CIFilterBuiltins
import Dependencies
import Foundation
import OSLog
import SharedModels

enum PlanShareResult: Sendable {
    /// A rendered QR image ready to display.
    case ready(CGImage)
    /// Plan is too large for a reliable QR code — file channel required (follow-up ticket).
    case tooLargeForQR
    /// Encoding or rendering failed — the view shows an error state.
    case failed
}

struct PlanShareClient: Sendable {
    /// Encodes the plan and renders its QR image off the main thread.
    var qrPayload: @Sendable (TrainingSession) async throws -> PlanShareResult
}

extension DependencyValues {
    var planShareClient: PlanShareClient {
        get { self[PlanShareClientKey.self] }
        set { self[PlanShareClientKey.self] = newValue }
    }
}

/// Diagnostic logger for the plan-share pipeline (DEBUG-only call sites).
private let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "WorkoutMirrorLive",
    category: "PlanShare"
)

private enum PlanShareClientKey: DependencyKey {

    static let liveValue = PlanShareClient(
        qrPayload: { plan in
            @Dependency(\.date.now) var now
            #if DEBUG
            logger.debug("[PlanShare] encode+render START")
            #endif
            let encoded = try SharedPlanCodec.encode(plan: plan, exportedAt: now)
            guard SharedPlanCodec.fitsInQR(encoded) else {
                #if DEBUG
                logger.debug("[PlanShare] tooLargeForQR (\(encoded.count) chars)")
                #endif
                return .tooLargeForQR
            }
            guard let image = makeQRImage(encoded) else { return .failed }
            #if DEBUG
            logger.debug("[PlanShare] encode+render DONE (\(encoded.count) chars)")
            #endif
            return .ready(image)
        }
    )

    static var previewValue: PlanShareClient {
        PlanShareClient(
            qrPayload: { _ in
                makeQRImage("preview-plan-payload").map(PlanShareResult.ready) ?? .failed
            }
        )
    }

    static var testValue: PlanShareClient {
        PlanShareClient(qrPayload: unimplemented("PlanShareClient.qrPayload"))
    }

    // MARK: - QR rendering

    /// Shared CIContext — Metal setup is expensive, reuse across renders.
    private static let qrContext = CIContext()

    /// Renders an encoded payload to a QR image. Called only from the async
    /// `qrPayload` closure, so the CIFilter work runs off the main thread —
    /// the view never blocks on it during body evaluation.
    private static func makeQRImage(_ payload: String) -> CGImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(payload.utf8)
        filter.correctionLevel = "M"
        guard let output = filter.outputImage else { return nil }
        let scaled = output.transformed(by: .init(scaleX: 10, y: 10))
        return qrContext.createCGImage(scaled, from: scaled.extent)
    }
}
