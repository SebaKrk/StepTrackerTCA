//
//  SandbagShape.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 27/11/2026.
//

import SwiftUI

/// Sandbag outline for stroking, drawn like a powerbag: a lying cylinder with end caps, two top handles and a band.
struct SandbagShape: Shape {

    func path(in rect: CGRect) -> Path {
        let grid = EquipmentSymbolGrid(rect: rect)
        let point = grid.point
        var path = Path(roundedRect: grid.frame(2.6, 9.4, 18.8, 9.8), cornerRadius: grid.length(4.9))

        path.move(to: point(6.4, 9.6))
        path.addCurve(to: point(6.4, 19), control1: point(7.5, 11), control2: point(7.5, 17.6))
        path.move(to: point(17.6, 9.6))
        path.addCurve(to: point(17.6, 19), control1: point(16.5, 11), control2: point(16.5, 17.6))

        path.move(to: point(8.4, 9.4))
        path.addCurve(to: point(11.2, 9.4), control1: point(8.4, 6.6), control2: point(11.2, 6.6))
        path.move(to: point(12.8, 9.4))
        path.addCurve(to: point(15.6, 9.4), control1: point(12.8, 6.6), control2: point(15.6, 6.6))

        path.move(to: point(7.6, 14.3))
        path.addLine(to: point(16.4, 14.3))

        return path
    }
}
