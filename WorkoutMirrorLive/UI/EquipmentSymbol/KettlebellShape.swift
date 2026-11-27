//
//  KettlebellShape.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 27/11/2026.
//

import SwiftUI

/// Kettlebell outline for stroking: round body on a flat base, handle with its window. SF Symbols has none.
struct KettlebellShape: Shape {

    func path(in rect: CGRect) -> Path {
        let point = EquipmentSymbolGrid(rect: rect).point
        var path = Path()

        path.move(to: point(7.2, 20.5))
        path.addLine(to: point(16.8, 20.5))
        path.addCurve(to: point(19.5, 14.8), control1: point(18.6, 19), control2: point(19.5, 17))
        path.addCurve(to: point(17.2, 9.6), control1: point(19.5, 12.7), control2: point(18.6, 10.9))
        path.addLine(to: point(17.6, 6.8))
        path.addCurve(to: point(14.4, 3.2), control1: point(17.8, 4.8), control2: point(16.4, 3.2))
        path.addLine(to: point(9.6, 3.2))
        path.addCurve(to: point(6.4, 6.8), control1: point(7.6, 3.2), control2: point(6.2, 4.8))
        path.addLine(to: point(6.8, 9.6))
        path.addCurve(to: point(4.5, 14.8), control1: point(5.4, 10.9), control2: point(4.5, 12.7))
        path.addCurve(to: point(7.2, 20.5), control1: point(4.5, 17), control2: point(5.4, 19))
        path.closeSubpath()

        path.move(to: point(9.3, 9.1))
        path.addLine(to: point(8.9, 6.9))
        path.addCurve(to: point(10.2, 5.4), control1: point(8.8, 6.1), control2: point(9.4, 5.4))
        path.addLine(to: point(13.8, 5.4))
        path.addCurve(to: point(15.1, 6.9), control1: point(14.6, 5.4), control2: point(15.2, 6.1))
        path.addLine(to: point(14.7, 9.1))
        path.addCurve(to: point(12, 8.6), control1: point(13.9, 8.8), control2: point(13, 8.6))
        path.addCurve(to: point(9.3, 9.1), control1: point(11, 8.6), control2: point(10.1, 8.8))
        path.closeSubpath()

        return path
    }
}
