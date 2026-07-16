//
//  PlanQRCodeView.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 13/07/2026.
//

import SwiftUI

/// Displays a pre-rendered QR image. Rendering happens off the main thread in
/// `PlanShareClient` — this view only draws the result.
struct PlanQRCodeView: View {

    let cgImage: CGImage

    var body: some View {
        Image(decorative: cgImage, scale: 1.0)
            .interpolation(.none)
            .resizable()
            .scaledToFit()
    }
}
