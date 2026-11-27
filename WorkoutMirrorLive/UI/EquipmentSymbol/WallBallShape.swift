//
//  WallBallShape.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 27/11/2026.
//

import SwiftUI

/// Wall ball outline for stroking: a soft medicine ball with its panel seams.
struct WallBallShape: Shape {

    func path(in rect: CGRect) -> Path {
        let grid = EquipmentSymbolGrid(rect: rect)
        let point = grid.point
        var path = Path(ellipseIn: grid.frame(3.4, 3.4, 17.2, 17.2))

        path.move(to: point(8.7, 4.1))
        path.addQuadCurve(to: point(8.7, 19.9), control: point(5.6, 12))
        path.move(to: point(15.3, 4.1))
        path.addQuadCurve(to: point(15.3, 19.9), control: point(18.4, 12))

        path.move(to: point(3.6, 12))
        path.addLine(to: point(6.8, 12))
        path.move(to: point(17.2, 12))
        path.addLine(to: point(20.4, 12))

        return path
    }
}
