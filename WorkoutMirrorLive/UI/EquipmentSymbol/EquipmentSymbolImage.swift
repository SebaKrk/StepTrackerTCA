//
//  EquipmentSymbolImage.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 27/11/2026.
//

import SwiftUI

/// Icon beside an equipment name: an SF Symbol, or one of the app's own drawings for kit SF Symbols lacks.
struct EquipmentSymbolImage: View {

    /// Name prefix of the app's own drawings.
    static let customPrefix = "custom."

    /// An SF Symbol name, or "custom.kettlebell" / "custom.sandbag" / "custom.wallball".
    let name: String

    var body: some View {
        if let shape = customShape {
            // A hidden SF Symbol sizes the drawing like any symbol in the same font.
            Image(systemName: "square")
                .hidden()
                .overlay {
                    GeometryReader { geometry in
                        shape.stroke(style: strokeStyle(for: geometry.size))
                    }
                }
        } else {
            Image(systemName: name)
        }
    }

    // MARK: - Implementation

    private var customShape: AnyShape? {
        switch name {
        case "\(Self.customPrefix)kettlebell": AnyShape(KettlebellShape())
        case "\(Self.customPrefix)sandbag": AnyShape(SandbagShape())
        case "\(Self.customPrefix)wallball": AnyShape(WallBallShape())
        default: nil
        }
    }

    /// Line weight close to a regular-weight SF Symbol at the same size.
    private func strokeStyle(for size: CGSize) -> StrokeStyle {
        StrokeStyle(lineWidth: max(1, min(size.width, size.height) * 0.08), lineCap: .round, lineJoin: .round)
    }
}

// MARK: - Previews

#Preview("Equipment symbols") {
    VStack(alignment: .leading, spacing: 12) {
        Label { Text("Kettlebell") } icon: { EquipmentSymbolImage(name: "custom.kettlebell") }
        Label { Text("Sandbag") } icon: { EquipmentSymbolImage(name: "custom.sandbag") }
        Label { Text("Wall ball") } icon: { EquipmentSymbolImage(name: "custom.wallball") }
        Label { Text("Barbell") } icon: { EquipmentSymbolImage(name: "dumbbell") }
        Label { Text("Kettlebell") } icon: { EquipmentSymbolImage(name: "custom.kettlebell") }
            .font(.system(size: 11))
        Label { Text("Kettlebell") } icon: { EquipmentSymbolImage(name: "custom.kettlebell") }
            .font(.largeTitle)
    }
    .padding()
}
