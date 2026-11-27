//
//  ChatBubbleShape.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 27/11/2026.
//

import SwiftUI

/// Rounded message bubble with a small tail at a bottom corner, pointing at who wrote it.
struct ChatBubbleShape: Shape {

    /// True for the user's messages: the tail sits bottom-right; the model's sit bottom-left.
    let isTailTrailing: Bool

    /// Corner radius of the bubble body.
    private let cornerRadius: CGFloat = 18

    /// Room the tail takes beside the body.
    private let tailWidth: CGFloat = 6

    func path(in rect: CGRect) -> Path {
        let body = CGRect(x: rect.minX, y: rect.minY, width: rect.width - tailWidth, height: rect.height)
        var path = Path(roundedRect: body, cornerRadius: cornerRadius, style: .continuous)

        // The tail grows out of the body's bottom corner and curls back under it.
        var tail = Path()
        tail.move(to: CGPoint(x: body.maxX - 2, y: body.maxY - 16))
        tail.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.maxY),
            control: CGPoint(x: body.maxX - 1, y: body.maxY - 3)
        )
        tail.addQuadCurve(
            to: CGPoint(x: body.maxX - 14, y: body.maxY),
            control: CGPoint(x: body.maxX - 5, y: body.maxY + 1)
        )
        tail.closeSubpath()
        path.addPath(tail)

        guard !isTailTrailing else { return path }
        return path.applying(CGAffineTransform(a: -1, b: 0, c: 0, d: 1, tx: rect.minX * 2 + rect.width, ty: 0))
    }
}
