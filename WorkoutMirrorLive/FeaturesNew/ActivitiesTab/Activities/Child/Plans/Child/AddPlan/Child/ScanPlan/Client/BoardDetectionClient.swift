//
//  BoardDetectionClient.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 26/11/2026.
//

import ComposableArchitecture
import CoreGraphics
import Vision

/// Finds the training board in a photo, so the crop can start around it.
struct BoardDetectionClient {

    /// Unit rectangle (0…1, top-left origin) around the board in an upright image; `nil` when none is found.
    var boardRect: @Sendable (_ image: CGImage) async -> CGRect?
}

extension DependencyValues {

    /// On-device board detection for the crop step.
    var boardDetection: BoardDetectionClient {
        get { self[BoardDetectionClientKey.self] }
        set { self[BoardDetectionClientKey.self] = newValue }
    }
}

private enum BoardDetectionClientKey: DependencyKey {

    /// Vision's document segmentation, read as a bounding box around the four corners.
    static let liveValue = BoardDetectionClient(
        boardRect: { image in
            // Local, so the detached closure reads no actor-isolated statics.
            let margin: CGFloat = 0.02
            let smallestSide: CGFloat = 0.15
            let smallestArea: CGFloat = 0.2
            guard let board = try? await DetectDocumentSegmentationRequest().perform(on: image),
                  board.confidence >= 0.5
            else { return nil }
            // Vision measures from the bottom-left; the crop measures from the top-left.
            let corners = [board.topLeft, board.topRight, board.bottomRight, board.bottomLeft]
            let xs = corners.map(\.x)
            let ys = corners.map { 1 - $0.y }
            guard let minX = xs.min(), let maxX = xs.max(), let minY = ys.min(), let maxY = ys.max() else { return nil }
            let rect = CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
                .insetBy(dx: -margin, dy: -margin)
                .intersection(CGRect(x: 0, y: 0, width: 1, height: 1))
            // A sliver or a sheet taped to the board is a misread: the default crop serves better.
            guard rect.width >= smallestSide, rect.height >= smallestSide,
                  rect.width * rect.height >= smallestArea
            else { return nil }
            return rect
        }
    )

    /// Finds nothing, so tests keep the default crop unless they override it.
    static let testValue = BoardDetectionClient(boardRect: { _ in nil })

    /// Finds nothing; previews show the default crop.
    static let previewValue = BoardDetectionClient(boardRect: { _ in nil })
}
