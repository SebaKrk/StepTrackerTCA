//
//  BoardCameraView.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 26/11/2026.
//

import SwiftUI

/// Our own camera for photographing a training board — one shutter tap, then the crop step.
struct BoardCameraView: UIViewControllerRepresentable {

    /// Called once when the camera session ends.
    let onResult: (BoardCameraResult) -> Void

    func makeUIViewController(context: Context) -> BoardCameraViewController {
        let controller = BoardCameraViewController()
        controller.onResult = onResult
        return controller
    }

    func updateUIViewController(_ controller: BoardCameraViewController, context: Context) {
        controller.onResult = onResult
    }
}
