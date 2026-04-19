//
//  ChartLoadingPlaceholder.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 18/04/2026.
//

import SwiftUI

/// Chart-shaped skeleton placeholder displayed during data loading.
/// Mimics the structure of a real chart (bars + summary row) so the
/// skeleton shimmer has consistent content to animate over.
struct ChartLoadingPlaceholder: View {

    private let barHeights: [CGFloat] = [55, 95, 70, 130, 80, 110, 60, 100, 85, 120, 65, 90]

    var body: some View {
        VStack(spacing: 8) {
            // Fake chart area
            HStack(alignment: .bottom, spacing: 5) {
                ForEach(Array(barHeights.enumerated()), id: \.offset) { _, height in
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.secondary.opacity(0.12))
                        .frame(maxWidth: .infinity)
                        .frame(height: height * 0.85)
                }
            }
            .frame(height: 140)
            .frame(maxWidth: .infinity)

            Divider()

            // Fake summary row
            HStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { _ in
                    VStack(alignment: .leading, spacing: 5) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.secondary.opacity(0.12))
                            .frame(width: 44, height: 9)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.secondary.opacity(0.12))
                            .frame(width: 68, height: 16)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }
}
