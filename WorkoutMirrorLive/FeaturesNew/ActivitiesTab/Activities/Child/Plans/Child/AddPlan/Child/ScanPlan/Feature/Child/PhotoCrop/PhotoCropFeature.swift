//
//  PhotoCropFeature.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 29/10/2026.
//

import ComposableArchitecture
import CoreGraphics
import Foundation
import SwiftUI
import UIKit

/// Crops a photo to the board before it leaves the phone.
///
/// Camera and library photos both pass here, so attendance lists and faces stay out of the upload.
@Reducer
struct PhotoCropFeature {

    /// Smallest crop side, in unit coordinates.
    static let minimumSide: CGFloat = 0.15

    // MARK: - Dependency

    @Dependency(\.boardDetection) var boardDetection

    // MARK: - State

    @ObservableState
    struct State {

        /// Full photo from the camera or the library; the crop is cut from this.
        let imageData: Data

        /// Small upright copy for the screen, decoded once — a 12 MP decode per drag would stutter.
        let previewImage: UIImage?

        /// Crop rectangle in unit coordinates of the photo (0…1 on both axes).
        var crop = CGRect(x: 0.05, y: 0.05, width: 0.9, height: 0.9)

        /// True while the cropped JPEG is being produced.
        var isCropping = false

        /// True once the user moved the crop; a late board detection must not undo their choice.
        var isCropEdited = false

        /// Decodes the screen copy once, when the crop sheet opens.
        init(imageData: Data) {
            self.imageData = imageData
            self.previewImage = PhotoCropper.previewImage(from: imageData)
        }
    }

    /// Handle the user is dragging.
    enum Corner: Sendable {

        /// Top-left handle.
        case topLeft

        /// Top-right handle.
        case topRight

        /// Bottom-left handle.
        case bottomLeft

        /// Bottom-right handle.
        case bottomRight
    }

    // MARK: - Action

    @CasePathable
    enum Action: ViewAction {
        case view(View)
        case `internal`(Internal)
        case delegate(Delegate)

        @CasePathable
        enum View {

            /// The crop screen appeared — looks for the board.
            case task

            /// A corner handle was dragged to this point in unit coordinates.
            case cornerMoved(Corner, CGPoint)

            /// User wants the whole photo.
            case useFullPhotoTapped

            /// User accepted the crop.
            case confirmTapped

            /// User abandoned the photo.
            case cancelTapped
        }

        enum Internal {

            /// The board's unit rectangle, or nil when none was found.
            case boardDetected(CGRect?)

            /// Cropped JPEG, or nil when re-encoding failed.
            case cropped(Data?)
        }

        enum Delegate {

            /// The photo to scan, cropped to the board.
            case cropped(Data)

            /// No photo to scan.
            case cancelled
        }
    }

    // MARK: - Body

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {

            case .view(.task):
                guard let image = state.previewImage?.cgImage else { return .none }
                return .run { [boardDetection] send in
                    let rect = await boardDetection.boardRect(image)
                    await send(.internal(.boardDetected(rect)), animation: .default)
                }

            case let .view(.cornerMoved(corner, point)):
                state.isCropEdited = true
                state.crop = Self.moved(state.crop, corner: corner, to: point)
                return .none

            case .view(.useFullPhotoTapped):
                state.isCropEdited = true
                state.crop = CGRect(x: 0, y: 0, width: 1, height: 1)
                return .none

            case let .internal(.boardDetected(rect)):
                guard let rect, !state.isCropEdited, !state.isCropping else { return .none }
                state.crop = rect
                return .none

            case .view(.confirmTapped):
                guard !state.isCropping else { return .none }
                state.isCropping = true
                return .run { [data = state.imageData, crop = state.crop] send in
                    await send(.internal(.cropped(PhotoCropper.jpeg(from: data, unitRect: crop))))
                }

            case .view(.cancelTapped):
                return .send(.delegate(.cancelled))

            case let .internal(.cropped(data)):
                state.isCropping = false
                // A failed re-encode still yields a scan: the uncropped original.
                return .send(.delegate(.cropped(data ?? state.imageData)))

            case .delegate:
                return .none
            }
        }
    }

    // MARK: - Private

    /// Moves one corner, keeping the rectangle inside the photo and above the minimum size.
    private static func moved(_ rect: CGRect, corner: Corner, to point: CGPoint) -> CGRect {
        let x = min(max(point.x, 0), 1)
        let y = min(max(point.y, 0), 1)
        var minX = rect.minX, maxX = rect.maxX, minY = rect.minY, maxY = rect.maxY
        switch corner {
        case .topLeft:
            minX = min(x, maxX - minimumSide)
            minY = min(y, maxY - minimumSide)
        case .topRight:
            maxX = max(x, minX + minimumSide)
            minY = min(y, maxY - minimumSide)
        case .bottomLeft:
            minX = min(x, maxX - minimumSide)
            maxY = max(y, minY + minimumSide)
        case .bottomRight:
            maxX = max(x, minX + minimumSide)
            maxY = max(y, minY + minimumSide)
        }
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }
}
