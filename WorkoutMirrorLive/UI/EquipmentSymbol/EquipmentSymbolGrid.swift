//
//  EquipmentSymbolGrid.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 27/11/2026.
//

import SwiftUI

/// The 24-point drawing grid of the equipment symbols, fitted into the rect a shape is asked to fill.
struct EquipmentSymbolGrid {

    /// The rect the symbol is drawn into.
    let rect: CGRect

    /// Grid points per screen point, keeping the drawing square.
    private var scale: CGFloat { min(rect.width, rect.height) / 24 }

    /// A grid coordinate on screen, centred in the rect.
    func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
        CGPoint(x: rect.midX + (x - 12) * scale, y: rect.midY + (y - 12) * scale)
    }

    /// A grid length on screen.
    func length(_ value: CGFloat) -> CGFloat {
        value * scale
    }

    /// A grid rectangle on screen.
    func frame(_ x: CGFloat, _ y: CGFloat, _ width: CGFloat, _ height: CGFloat) -> CGRect {
        let origin = point(x, y)
        return CGRect(x: origin.x, y: origin.y, width: length(width), height: length(height))
    }
}
