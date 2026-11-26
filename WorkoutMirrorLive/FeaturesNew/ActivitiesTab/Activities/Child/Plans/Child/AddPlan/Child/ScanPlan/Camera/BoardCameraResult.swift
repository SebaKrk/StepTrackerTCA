//
//  BoardCameraResult.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 26/11/2026.
//

import Foundation

/// Outcome of a board camera session; a cancel is not an error and the reducer treats it apart.
enum BoardCameraResult {

    /// The full photo, as the camera encoded it.
    case captured(Data)

    /// The user closed the camera.
    case cancelled

    /// No camera, no permission, or the session could not start.
    case failed
}
